# frozen_string_literal: true

require "json"
require "securerandom"

module PhComposer
  module Export
    # Writes the HBJSON and its report as one pair, or leaves the destination as it was. Both files are
    # staged beside the destination and verified, a journal records the plan, then the previous pair
    # (if any) moves aside and the new pair is renamed into place. A run interrupted at any step is
    # rolled back from the journal by the next run to the same destination. `fault` is a test hook
    # called at each named step.
    module ArtifactPair
      class PairError < UserError; end
      class IncompletePriorPairError < PairError; end

      Result = Struct.new(:hbjson_path, :report_path, :replaced, keyword_init: true)

      class Transaction
        attr_reader :hbjson_path, :report_path

        def initialize(hbjson_path, run_id:, fault: nil)
          @hbjson_path = File.expand_path(hbjson_path.to_s)
          unless @hbjson_path.downcase.end_with?(".hbjson")
            raise PairError, "The export destination must end in .hbjson."
          end
          @report_path = ArtifactPair.report_path(@hbjson_path)
          @directory = File.dirname(@hbjson_path)
          @run_id = run_id.to_s
          raise PairError, "The export run id is missing." if @run_id.empty?
          @fault = fault
          @owned = []
        end

        def commit(hbjson, report_html)
          @committed = false
          recover
          assert_prior_pair!
          paths = owned_paths
          @owned = paths.values
          prior = File.exist?(@hbjson_path)
          journal = journal_payload(paths, prior)
          write_journal(paths, journal)
          trip(:after_journal)
          write_exclusive(paths.fetch("hbjson_stage"), hbjson)
          trip(:after_hbjson_stage)
          write_exclusive(paths.fetch("report_stage"), report_html)
          trip(:after_report_stage)
          verify_staged!(paths, hbjson, report_html)

          if prior
            File.rename(@hbjson_path, paths.fetch("hbjson_backup"))
            trip(:after_hbjson_backup)
            File.rename(@report_path, paths.fetch("report_backup"))
            trip(:after_report_backup)
          end
          File.rename(paths.fetch("hbjson_stage"), @hbjson_path)
          trip(:after_hbjson_commit)
          File.rename(paths.fetch("report_stage"), @report_path)
          trip(:after_report_commit)
          verify_final!(hbjson, report_html)
          mark_committed(paths, journal)
          @committed = true
          cleanup_committed(paths)
          Result.new(:hbjson_path => @hbjson_path, :report_path => @report_path, :replaced => prior)
        rescue StandardError => error
          if @committed
            cleanup_committed(paths) if paths
            return Result.new(:hbjson_path => @hbjson_path, :report_path => @report_path, :replaced => prior)
          end
          restore_from_journal
          @owned.each { |path| safe_delete(path) }
          raise error if error.is_a?(PairError)
          raise PairError, "The coordinated artifact pair could not be committed (#{error.class}: #{error.message})."
        ensure
          @owned = []
        end

        def recover
          safe_delete(journal_stage_path) unless File.file?(journal_path)
          restore_from_journal
          true
        end

        private

        def owned_paths
          token = @run_id.gsub(/[^A-Za-z0-9_-]/, "_") + "-" + SecureRandom.hex(6)
          hb_name = File.basename(@hbjson_path)
          report_name = File.basename(@report_path)
          {
            "hbjson_stage" => File.join(@directory, ".#{hb_name}.ph-composer-export-#{token}.stage"),
            "report_stage" => File.join(@directory, ".#{report_name}.ph-composer-export-#{token}.stage"),
            "hbjson_backup" => File.join(@directory, ".#{hb_name}.ph-composer-export-#{token}.backup"),
            "report_backup" => File.join(@directory, ".#{report_name}.ph-composer-export-#{token}.backup"),
            "journal" => journal_path,
            "journal_stage" => journal_stage_path
          }
        end

        def journal_path
          File.join(@directory, ".#{File.basename(@hbjson_path)}.ph-composer-export-commit.json")
        end

        def journal_stage_path
          journal_path + ".stage"
        end

        def journal_payload(paths, prior)
          {
            "schema_version" => 1,
            "state" => "prepared",
            "run_id" => @run_id,
            "prior_pair" => prior,
            "hbjson_final" => File.basename(@hbjson_path),
            "report_final" => File.basename(@report_path),
            "hbjson_stage" => File.basename(paths.fetch("hbjson_stage")),
            "report_stage" => File.basename(paths.fetch("report_stage")),
            "hbjson_backup" => File.basename(paths.fetch("hbjson_backup")),
            "report_backup" => File.basename(paths.fetch("report_backup"))
          }
        end

        def restore_from_journal
          return unless File.file?(journal_path)
          journal = JSON.parse(File.read(journal_path))
          validate_journal!(journal)
          paths = journal.transform_values do |value|
            value.is_a?(String) && value.start_with?(".") ? File.join(@directory, value) : value
          end
          paths["journal"] = journal_path
          paths["journal_stage"] = journal_stage_path
          hb_backup = paths["hbjson_backup"]
          report_backup = paths["report_backup"]
          if journal["state"] == "committed"
            cleanup_committed(paths)
            return
          end
          if journal["prior_pair"]
            safe_delete(@hbjson_path) if File.exist?(hb_backup) && File.exist?(@hbjson_path)
            safe_delete(@report_path) if File.exist?(report_backup) && File.exist?(@report_path)
            File.rename(hb_backup, @hbjson_path) if File.exist?(hb_backup)
            File.rename(report_backup, @report_path) if File.exist?(report_backup)
          else
            safe_delete(@hbjson_path)
            safe_delete(@report_path)
          end
          # The journal stage too: a run lost while marking the journal committed leaves one beside the
          # prepared journal. The journal goes last, so an interruption here is recovered again.
          %w[hbjson_stage report_stage hbjson_backup report_backup journal_stage].each do |key|
            safe_delete(paths[key])
          end
          safe_delete(journal_path)
        rescue JSON::ParserError, KeyError => error
          raise PairError, "The prior Export commit journal is unreadable (#{error.message})."
        end

        def validate_journal!(journal)
          raise PairError, "The prior Export commit journal has the wrong schema." unless journal["schema_version"] == 1
          unless %w[prepared committed].include?(journal.fetch("state"))
            raise PairError, "The prior Export commit journal has an invalid state."
          end
          expected = {
            "hbjson_final" => File.basename(@hbjson_path),
            "report_final" => File.basename(@report_path)
          }
          expected.each do |key, value|
            next if journal.fetch(key) == value

            raise PairError, "The prior Export commit journal targets another artifact."
          end
          %w[hbjson_stage report_stage hbjson_backup report_backup].each do |key|
            name = journal.fetch(key)
            unless File.basename(name) == name && name.start_with?(".") && name.include?(".ph-composer-export-")
              raise PairError, "The prior Export commit journal contains an unsafe path."
            end
          end
        end

        def assert_prior_pair!
          hb_exists = File.exist?(@hbjson_path)
          report_exists = File.exist?(@report_path)
          return if hb_exists == report_exists
          raise IncompletePriorPairError,
                "Only one destination artifact exists. Move or rename it before replacing the coordinated pair."
        end

        def write_exclusive(path, content)
          # The final files take the user's ordinary permissions (0666 less the umask), like any saved file.
          File.open(path, File::WRONLY | File::CREAT | File::EXCL, 0o666) do |file|
            file.write(content)
            file.flush
            file.fsync
          end
        end

        def write_journal(paths, journal)
          write_exclusive(paths.fetch("journal_stage"), JSON.generate(journal))
          File.rename(paths.fetch("journal_stage"), paths.fetch("journal"))
        end

        def verify_staged!(paths, hbjson, report_html)
          unless File.binread(paths["hbjson_stage"]) == hbjson.b
            raise PairError, "The staged HBJSON does not match the serialized export."
          end
          unless File.binread(paths["report_stage"]) == report_html.b
            raise PairError, "The staged report does not match the rendered export."
          end
          JSON.parse(hbjson)
          unless report_html.include?(@run_id) && report_html.include?(Report::RESULT_ELEMENT_ID)
            raise PairError, "The staged report does not identify the export run."
          end
        rescue JSON::ParserError => error
          raise PairError, "The staged HBJSON is invalid JSON (#{error.message})."
        end

        def verify_final!(hbjson, report_html)
          unless File.binread(@hbjson_path) == hbjson.b && File.binread(@report_path) == report_html.b
            raise PairError, "The final artifact pair failed byte verification."
          end
        end

        def mark_committed(paths, journal)
          committed = journal.merge("state" => "committed")
          write_exclusive(paths.fetch("journal_stage"), JSON.generate(committed))
          trip(:after_committed_journal_stage)
          File.rename(paths.fetch("journal_stage"), paths.fetch("journal"))
        end

        def cleanup_committed(paths)
          safe_delete(paths["hbjson_backup"])
          trip(:after_hbjson_backup_cleanup)
          safe_delete(paths["report_backup"])
          trip(:after_report_backup_cleanup)
          %w[hbjson_stage report_stage journal_stage journal].each do |key|
            safe_delete(paths[key])
          end
        rescue StandardError
          # Both final files were byte-verified and the journal is marked committed. Leave any
          # remaining journal and backups for the next run to clean without rolling back the pair.
          nil
        end

        def safe_delete(path)
          return unless path && File.file?(path)
          File.delete(path)
        end

        def trip(point)
          @fault.call(point) if @fault
        end
      end

      module_function

      def report_path(hbjson_path)
        base = hbjson_path.to_s.sub(/\.hbjson\z/i, "")
        base + "-export-report.html"
      end
    end
  end
end
