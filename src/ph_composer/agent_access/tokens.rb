# frozen_string_literal: true

require "digest"
require "json"
require "securerandom"
require "time"

module PhComposer
  module AgentAccess
    # The agent access tokens issued on this machine (context/AGENT_INTERFACE.md, "User-controlled
    # local access"). A token is the connection: a label, the capabilities chosen when it was issued
    # and a revoke control. The store keeps only the token's SHA-256; the token itself is returned once,
    # to the Agent Access dialog that issued it, and never stored, logged or offered through
    # PhComposer::API, so no grant lets an agent list, issue or revoke one.
    #
    # Machine state read on every call, like ApprovedLocations, whose storage shape this copies: base64
    # JSON in SketchUp's defaults, a byte cap, an unreadable store reported and never silently replaced.
    # A revoked token stays as a row with `revoked_at`, so the dialog can show when it was revoked.
    module Tokens
      SECTION = "ph_composer.agent_access"
      KEY = "tokens"
      MAX_LIVE = 8
      MAX_REVOKED = 32
      MAX_STORED_BYTES = 64 * 1024
      LABEL_LENGTH = 80
      DEFAULT_LABEL = "Agent token"
      # What a token may be issued with. Every token holds `read`; the other capabilities are offered
      # once their consent copy and enforcement exist.
      OFFERED = %w[read].freeze
      PUBLIC_KEYS = %w[id label capabilities created_at last_used_at revoked_at].freeze
      ROW_KEYS = (PUBLIC_KEYS + ["token_sha256"]).freeze
      UNREADABLE = "The agent tokens stored on this machine cannot be read. Reset them before issuing another; " \
                   "every agent must then be given a new token."

      module_function

      # "readable" (including nothing stored yet) or "unreadable".
      def state
        stored.fetch("state")
      end

      # Every token, live and revoked, without its digest; live ones first, newest first in each.
      def list
        live, revoked = rows.partition { |row| row["revoked_at"].nil? }
        (live.reverse + revoked.reverse).map { |row| public_row(row) }
      end

      # Issues a token and returns `{"token" => secret, "row" => public row}`. The secret is not kept.
      def issue(label: nil, capabilities: OFFERED)
        current = writable
        granted = checked_capabilities(capabilities)
        live = current.count { |row| row["revoked_at"].nil? }
        if live >= MAX_LIVE
          raise CodedError.new("agent_access.limit", "This machine already has #{MAX_LIVE} live agent tokens. " \
                                                     "Revoke one before issuing another.")
        end

        token = SecureRandom.hex(24)
        row = { "id" => Records::Identity.mint("token"), "label" => label ? checked_label(label) : next_label(current),
                "capabilities" => granted, "created_at" => now, "last_used_at" => nil, "revoked_at" => nil,
                "token_sha256" => digest(token) }
        save(current + [row])
        { "token" => token, "row" => public_row(row) }
      end

      # Ends a token for good. Revoking an already revoked token changes nothing.
      def revoke(id)
        current = writable
        row = current.find { |item| item["id"] == id }
        unless row
          raise CodedError.new("agent_access.token_unknown", "There is no agent token #{id.to_s[0, 40].inspect}.")
        end
        return list if row["revoked_at"]

        save(current.map { |item| item.equal?(row) ? item.merge("revoked_at" => now) : item })
        list
      end

      # Replaces an unreadable store with an empty one; a readable store is left as it is.
      def reset
        save([]) if state == "unreadable"
        list
      end

      # Whether any token is live; the listener runs only while one is.
      def live?
        rows.any? { |row| row["revoked_at"].nil? }
      end

      # The live tokens by the hex SHA-256 of their secret, each with its public row, frozen. The
      # ingress compares a presented token's digest against these keys and touches nothing else.
      def snapshot
        rows.select { |row| row["revoked_at"].nil? }
            .to_h { |row| [row.fetch("token_sha256"), public_row(row)] }
            .then { |table| DeepCopy.frozen(table) }
      end

      def digest(token)
        Digest::SHA256.hexdigest(token.to_s)
      end

      def public_row(row)
        row.slice(*PUBLIC_KEYS)
      end

      def checked_capabilities(capabilities)
        granted = Array(capabilities).map(&:to_s).uniq
        unless granted.include?("read") && (granted - OFFERED).empty?
          raise CodedError.new("params.invalid", "A token holds read and may add only #{OFFERED.join(', ')}.")
        end

        CallerRegistry::CAPABILITIES.select { |name| granted.include?(name) }
      end

      def checked_label(label)
        text = label.to_s.strip
        return text if !text.empty? && text.length <= LABEL_LENGTH

        raise CodedError.new("params.invalid", "A token label is 1 to #{LABEL_LENGTH} characters.")
      end

      # "Agent token N", one past the highest such label still listed.
      def next_label(current)
        numbers = current.map { |row| row["label"].to_s[/\A#{DEFAULT_LABEL} (\d+)\z/, 1].to_i }
        "#{DEFAULT_LABEL} #{(numbers.max || 0) + 1}"
      end

      def now
        Time.now.utc.iso8601
      end

      def rows
        stored.fetch("tokens")
      end

      # The rows, refusing when the stored blob cannot be read: it is reported, never silently replaced.
      def writable
        store = stored
        raise CodedError.new("agent_access.store_unreadable", UNREADABLE) if store.fetch("state") == "unreadable"

        store.fetch("tokens")
      end

      def stored
        raw = Sketchup.read_default(SECTION, KEY, nil)
        return { "state" => "readable", "tokens" => [] } if raw.nil?
        return unreadable unless raw.is_a?(String) && raw.bytesize <= MAX_STORED_BYTES * 2

        document = JSON.parse(raw.unpack1("m0"))
        valid?(document) ? { "state" => "readable", "tokens" => document.fetch("tokens") } : unreadable
      rescue JSON::ParserError, ArgumentError, EncodingError
        unreadable
      end

      def unreadable
        { "state" => "unreadable", "tokens" => [] }
      end

      def valid?(document)
        document.is_a?(Hash) && document["tokens"].is_a?(Array) && document["tokens"].all? { |row| valid_row?(row) }
      end

      def valid_row?(row)
        row.is_a?(Hash) && (row.keys - ROW_KEYS).empty? && row["id"].is_a?(String) && row["label"].is_a?(String) &&
          row["token_sha256"].to_s.match?(/\A\h{64}\z/) && row["capabilities"].is_a?(Array) &&
          row["capabilities"].include?("read") && (row["capabilities"] - CallerRegistry::CAPABILITIES).empty?
      end

      # Keeps every live token and the newest MAX_REVOKED revoked ones, then tells the listener.
      def save(current)
        live, revoked = current.partition { |row| row["revoked_at"].nil? }
        kept = live + revoked.last(MAX_REVOKED)
        text = JSON.generate("tokens" => current.select { |row| kept.include?(row) }.map { |row| row.slice(*ROW_KEYS) })
        if text.bytesize > MAX_STORED_BYTES
          raise CodedError.new("agent_access.store_unavailable", "Agent tokens exceed their storage limit. " \
                                                                 "Revoke some first.")
        end
        unless Sketchup.write_default(SECTION, KEY, [text].pack("m0"))
          raise CodedError.new("agent_access.store_unavailable", "Agent tokens could not be saved.")
        end

        AgentAccess.tokens_changed
      end
    end
  end
end
