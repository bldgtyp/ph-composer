# frozen_string_literal: true

require "digest"
require "securerandom"

module PhComposer
  module Library
    # One file, one rename commit. The destination and stage remain private to this object. Every
    # pre-commit failure leaves prior destination bytes intact and removes only this writer's stage.
    class FileWriter
      def initialize(destination)
        @destination = destination.to_s.dup.freeze
        @prior = fingerprint
      rescue SystemCallError, IOError
        raise Error.new("library.export_write_failed", "The library destination could not be inspected."), :cause => nil
      end

      def inspect
        "#<#{self.class.name}>"
      end

      def prior_bytes
        return nil if @prior.nil?
        if File.size(@destination) > LibraryFile::MAX_BYTES
          raise Error.new("library.file_too_large", "The destination exceeds the 32 MiB library file limit.")
        end
        bytes = File.binread(@destination)
        verify_unchanged!
        bytes
      end

      def write(bytes)
        owned = false
        stage = File.join(File.dirname(@destination), ".ph-composer-library-#{SecureRandom.hex(16)}.tmp")
        File.open(stage, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
          owned = true
          file.binmode
          file.write(bytes)
          file.flush
          file.fsync
        end
        unless File.binread(stage) == bytes
          raise Error.new("library.export_write_failed", "The staged library file could not be verified.")
        end
        yield if block_given?
        verify_unchanged!
        File.rename(stage, @destination)
        stage = nil
        true
      rescue SystemCallError, IOError
        raise Error.new("library.export_write_failed", "The library file could not be written."), :cause => nil
      ensure
        begin
          File.delete(stage) if owned && stage && File.exist?(stage)
        rescue SystemCallError, IOError
          # A successful rename has committed. A cleanup error must not misreport that commit.
        end
      end

      def verify_unchanged!
        return if fingerprint == @prior

        raise Error.new("library.destination_changed", "The destination changed after review. Try again.")
      end

      private

      def fingerprint
        return nil unless File.exist?(@destination) || File.symlink?(@destination)
        unless File.file?(@destination) && !File.symlink?(@destination)
          raise Error.new("library.destination_invalid", "Choose a regular library file destination.")
        end
        Digest::SHA256.file(@destination).hexdigest
      end
    end
  end
end
