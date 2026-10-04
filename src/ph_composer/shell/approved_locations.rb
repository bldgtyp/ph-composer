# frozen_string_literal: true

require "json"
require "time"
require_relative "declarations"

module PhComposer
  # Files and folders the user approved once on this machine, so a caller holding the grant an
  # operation needs can name one by id instead of asking the user again (context/AGENT_INTERFACE.md,
  # "Locations only the user can choose"). The path stays in this store. `resolve` is the one method
  # that returns it, and only dispatch calls it; `observe` lends it to an exporter's state function
  # without returning it. Every public row carries the id and the label the user gave, never a path or
  # a file name.
  #
  # The store is machine state read on every call, as Library::Setup is, so it keeps nothing in memory.
  # A save destination is reused until revoked; an approved file or folder is used once, because the
  # library it adds then holds the path itself. A revoked or used id is kept as a bounded tombstone
  # so a caller is told why it no longer resolves.
  module ApprovedLocations
    FEATURE_ID = "ph_composer.locations"
    SECTION = "ph_composer.locations"
    KEY = "approved"
    MAX_STORED_BYTES = 256 * 1024
    TOMBSTONES = 100
    LABEL_LENGTH = 80
    UNREADABLE = "This machine's approved locations cannot be read. Reset them in the Libraries dialog " \
                 "before approving another; every location must be approved again."
    DEFAULT_LABELS = { "save_file" => "Export destination", "open_file" => "Library file",
                       "open_folder" => "Library folder" }.freeze
    USES = { "save_file" => "reusable", "open_file" => "single", "open_folder" => "single" }.freeze
    PUBLIC_KEYS = %w[id kind label use approved_at last_used_at].freeze
    ROW_KEYS = (PUBLIC_KEYS + ["path"]).freeze

    module_function

    # The `location` param registration adds to every operation whose Approval a location may answer
    # (every Approval that is not standing), so a feature's own schema never declares it.
    def param(kind)
      id = { "type" => "string", "minLength" => 1,
             "description" => "The id of a location the user approved, from ph_composer.locations.list." }
      properties = { "id" => id }
      if kind == "save_file"
        properties["replace"] = { "type" => "boolean", "description" => "Consent to replace what the destination " \
                                                                        "holds. Needs expected_destination." }
        properties["expected_destination"] = {
          "type" => "string", "minLength" => 1,
          "description" => "The destination state a preview reported, so a destination that changed since is refused."
        }
      end
      { "type" => "object", "additionalProperties" => false, "required" => ["id"], "properties" => properties,
        "description" => "An approved location to use instead of asking the user. A native client asks instead." }
    end

    # `params` with the `location` param composed in, unless the declaration already names one, which
    # registration then refuses.
    def with_param(params, approval)
      return params unless approval.is_a?(Declarations::Approval) && !approval.standing && params.is_a?(Hash) &&
                           params["properties"].is_a?(Hash) && !params["properties"].key?("location")

      params.merge("properties" => params["properties"].merge("location" => param(approval.kind)))
    end

    # The NativeApproval::Granted a `location` param stands for, with `params` less the location.
    def grant(location, kind)
      row = available(location.fetch("id"), kind)
      NativeApproval::Granted.new(:path => row.fetch("path"), :replace => location["replace"] == true,
                                  :state => location["expected_destination"], :label => row.fetch("label"),
                                  :location_id => row.fetch("id")).freeze
    end

    # As `grant`, for a `location` that has not been through an operation's params schema.
    def grant_param(location, kind)
      findings = location.is_a?(Hash) ? JsonValue.problems(location) : []
      findings = JsonSchema.validate(location, param(kind)) if findings.empty?
      unless findings.empty?
        raise CodedError.new("params.invalid", "The location is not valid: #{findings.first}.", "findings" => findings)
      end

      grant(location, kind)
    end

    # "readable" (including nothing stored yet) or "unreadable".
    def state
      stored.last
    end

    # Every approved location without its path, and whether it is there now.
    def list
      rows.map { |row| public_row(row) }
    end

    # Stores what the user chose in the native dialog and returns its public row.
    def approve(kind:, path:, label: nil)
      raise InternalError, "Unknown location kind #{kind.inspect}." unless USES.key?(kind)

      current, retired = writable
      row = { "id" => Records::Identity.mint("location"), "kind" => kind,
              "label" => label ? checked_label(label) : default_label(current, kind), "path" => path.to_s,
              "use" => USES.fetch(kind), "approved_at" => now, "last_used_at" => nil }
      save(current + [row], retired)
      public_row(row)
    end

    def rename(id, label)
      current, retired = writable
      row = find!(current, retired, id)
      save(current.map { |item| item.equal?(row) ? item.merge("label" => checked_label(label)) : item }, retired)
      public_row(row.merge("label" => checked_label(label)))
    end

    # Removes a location for good. Revoking only takes access away, so any `setup` caller may.
    def revoke(id)
      current, retired = writable
      row = find!(current, retired, id)
      save(current.reject { |item| item.equal?(row) }, retire(retired, id, "revoked"))
      list
    end

    # Replaces an unreadable store with an empty one; a readable store is left as it is.
    def reset
      write([], []) if state == "unreadable"
      list
    end

    # The path behind `id` for an operation that declared an approval of `kind`. Dispatch is the only
    # caller: it turns the path into the NativeApproval::Granted every handler already reads.
    def resolve(id, kind:)
      available(id, kind).fetch("path")
    end

    # Whether something is at the save destination `id` names, and its state by the exporter's own
    # function, `->(path) { string or nil }`. The path is yielded and never returned.
    def observe(id, kind: "save_file")
      path = resolve(id, :kind => kind)
      state = yield(path)
      { "exists" => !state.nil?, "state" => state }
    end

    # Records a completed use: the time for a reusable location, retirement for a single-use one.
    # A store that cannot be written now leaves the use unrecorded; the operation has already completed.
    def mark_used(id)
      current, retired = writable
      row = current.find { |item| item.fetch("id") == id }
      return unless row

      if row.fetch("use") == "single"
        save(current.reject { |item| item.equal?(row) }, retire(retired, id, "used"))
      else
        save(current.map { |item| item.equal?(row) ? item.merge("last_used_at" => now) : item }, retired)
      end
    rescue CodedError
      nil
    end

    def public_row(row)
      row.slice(*PUBLIC_KEYS).merge("available" => available?(row))
    end

    def available(id, kind)
      row = usable(id, kind)
      return row if available?(row)

      raise CodedError.new("location.unavailable", "The approved location #{row.fetch('label')} is no longer " \
                                                   "there as approved. Approve it again in the Libraries dialog.")
    end

    def usable(id, kind)
      current, retired, readable = stored
      raise CodedError.new("location.setup_unreadable", UNREADABLE) if readable == "unreadable"

      row = find!(current, retired, id)
      return row if row.fetch("kind") == kind

      raise CodedError.new("location.kind_mismatch", "The approved location #{row.fetch('label')} is a " \
                                                     "#{noun(row.fetch('kind'))}; this operation needs a " \
                                                     "#{noun(kind)}.")
    end

    def find!(current, retired, id)
      row = current.find { |item| item.fetch("id") == id }
      return row if row

      tombstone = retired.find { |item| item.fetch("id") == id }
      case tombstone&.fetch("reason")
      when "revoked"
        raise CodedError.new("location.revoked", "That approved location was revoked. Ask the user to approve " \
                                                 "it again.")
      when "used"
        raise CodedError.new("location.used", "That approved location was already used once; an approved file " \
                                              "or folder adds one library. Read the configured libraries.")
      end
      raise CodedError.new("location.unknown", "There is no approved location #{id.to_s[0, 40].inspect} on this " \
                                               "machine.")
    end

    def noun(kind)
      NativeApproval::NOUNS.fetch(kind)
    end

    def available?(row)
      path = row.fetch("path")
      case row.fetch("kind")
      when "open_file" then File.file?(path)
      when "open_folder" then File.directory?(path)
      else File.directory?(File.dirname(path)) && (!File.exist?(path) || File.file?(path))
      end
    end

    def default_label(current, kind)
      "#{DEFAULT_LABELS.fetch(kind)} #{current.count { |row| row.fetch('kind') == kind } + 1}"
    end

    def checked_label(label)
      text = label.to_s.strip
      return text if !text.empty? && text.length <= LABEL_LENGTH

      raise CodedError.new("params.invalid", "A location label is 1 to #{LABEL_LENGTH} characters.")
    end

    def retire(retired, id, reason)
      (retired + [{ "id" => id, "reason" => reason, "retired_at" => now }]).last(TOMBSTONES)
    end

    def now
      Time.now.utc.iso8601
    end

    def rows
      stored.first
    end

    # The rows and tombstones, refusing when the stored blob cannot be read: it is reported, never
    # silently replaced.
    def writable
      current, retired, readable = stored
      raise CodedError.new("location.setup_unreadable", UNREADABLE) if readable == "unreadable"

      [current, retired]
    end

    def stored
      raw = Sketchup.read_default(SECTION, KEY, nil)
      return [[], [], "readable"] if raw.nil?
      return [[], [], "unreadable"] unless raw.is_a?(String) && raw.bytesize <= MAX_STORED_BYTES * 2

      document = JSON.parse(raw.unpack1("m0"))
      return [[], [], "unreadable"] unless valid?(document)

      [document.fetch("locations"), document.fetch("retired"), "readable"]
    rescue JSON::ParserError, ArgumentError, EncodingError
      [[], [], "unreadable"]
    rescue SystemCallError, IOError
      raise CodedError.new("location.setup_unavailable", "Approved locations could not be read."), :cause => nil
    end

    def save(current, retired)
      write(current.map { |row| row.slice(*ROW_KEYS) }, retired)
      Sessions.all.each(&:request_refresh)
    end

    def write(current, retired)
      text = JSON.generate("locations" => current, "retired" => retired)
      if text.bytesize > MAX_STORED_BYTES
        raise CodedError.new("location.setup_unavailable", "Approved locations exceed their storage limit. " \
                                                           "Revoke some first.")
      end
      return if Sketchup.write_default(SECTION, KEY, [text].pack("m0"))

      raise CodedError.new("location.setup_unavailable", "Approved locations could not be saved.")
    rescue SystemCallError, IOError
      raise CodedError.new("location.setup_unavailable", "Approved locations could not be saved."), :cause => nil
    end

    def valid?(document)
      return false unless document.is_a?(Hash) && document.keys.sort == %w[locations retired]

      locations = document["locations"]
      retired = document["retired"]
      locations.is_a?(Array) && retired.is_a?(Array) && locations.all? { |row| valid_row?(row) } &&
        retired.all? { |row| row.is_a?(Hash) && row["id"].is_a?(String) && %w[revoked used].include?(row["reason"]) } &&
        locations.map { |row| row["id"] }.uniq.length == locations.length
    end

    def valid_row?(row)
      row.is_a?(Hash) && row.keys.sort == ROW_KEYS.sort && USES.key?(row["kind"]) &&
        Records::Identity.pattern("location").match?(row["id"].to_s) &&
        %w[label path approved_at].all? { |key| row[key].is_a?(String) && !row[key].empty? } &&
        row["use"] == USES[row["kind"]] && (row["last_used_at"].nil? || row["last_used_at"].is_a?(String))
    end
    private_class_method :public_row, :available, :usable, :find!, :noun, :available?, :default_label, :checked_label,
                         :retire, :now, :rows, :writable, :stored, :save, :write, :valid?, :valid_row?
  end
end
