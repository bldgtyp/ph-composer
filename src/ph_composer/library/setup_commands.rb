# frozen_string_literal: true

require_relative "setup"

module PhComposer
  module Library
    # The user chooses a library's file or folder in a native picker, which the panel or menu opens
    # before calling the command (Declarations::Approval); a scripted caller is refused. Only the
    # handler sees the path. Public results return configured labels.
    module SetupCommands
      PREFIX = "ph_composer.library.providers"
      ADDS = {
        "add_file" => Declarations::Approval.new(:kind => "open_file", :title => "Add library file",
                                                 :filter => "*.json").freeze,
        "add_folder" => Declarations::Approval.new(:kind => "open_folder", :title => "Add library folder").freeze
      }.freeze
      DESCRIPTIONS = {
        "add_file" => "Add a library file the user chooses in a native picker to this machine's libraries.",
        "add_folder" => "Add a folder of library files the user chooses in a native picker to this machine's " \
                        "libraries."
      }.freeze
      # A file is parsed whole; a folder lists its files, whose parse problems become catalog warnings.
      REFUSES = {
        "add_file" => %w[library.file_malformed library.file_too_large library.file_unreadable library.format_invalid
                         library.schema_unsupported library.setup_too_large library.setup_unavailable
                         library.setup_unreadable],
        "add_folder" => %w[library.catalog_too_large library.catalog_too_many_rows library.file_too_large
                           library.file_unreadable library.setup_too_large library.setup_unavailable
                           library.setup_unreadable]
      }.freeze

      module_function

      def install(feature)
        result = Schemas.list(Schemas.object({ "id" => Schemas::TEXT, "label" => Schemas::TEXT,
                                               "provider_kind" => Schemas::TEXT }))
        ADDS.each do |verb, approval|
          feature.setup_command("#{PREFIX}.#{verb}",
                                :description => DESCRIPTIONS.fetch(verb), :refuses => REFUSES.fetch(verb),
                                :params => Library.object({}), :result => result, :examples => [{}],
                                :approval => approval) do |request|
            kinds, adapters = kind_adapters(request.registry)
            value = add_path(request.approval.path, :kinds => kinds, :adapters => adapters,
                                                    :fallback => request.approval.label)
            refresh_sessions
            value
          end
          feature.menu_item("#{PREFIX}.#{verb}_menu", :label => verb == "add_file" ? "Add Library File…" :
                            "Add Library Folder…", :menu => "Libraries",
                                                      :available => ->(_read) { false }) do |session|
            # The picker would only lead to the same refusal; say so before it opens.
            next session.notice(Setup::UNREADABLE, :tone => :warning) if Setup.state == "unreadable"

            before = Setup.providers.map { |row| row.fetch("id") }
            outcome = NativeApproval.setup(menu_context(session), "#{PREFIX}.#{verb}", {})
            next if outcome["status"] == "cancelled"

            tone = outcome["status"] == "completed" ? :success : :warning
            session.notice(menu_message(outcome, before), :tone => tone)
          end
        end
        install_reset(feature, result)
        feature.setup_command("#{PREFIX}.remove",
                              :description => "Remove a configured library from this machine.",
                              :refuses => %w[library.setup_unavailable library.setup_unreadable],
                              :params => Library.object({ "provider_id" => Library.described(
                                Library::TEXT, "The configured library to remove from this machine."
                              ) }),
                              :result => result,
                              :examples => [{ "provider_id" => "example" }]) do |request|
          id = request.params.fetch("provider_id")
          value = Setup.remove(id)
          refresh_sessions
          value
        end
      end

      # An unreadable stored setup is reported, never silently replaced: changes refuse until reset.
      def install_reset(feature, result)
        feature.query("#{PREFIX}.setup_state",
                      :description => "Whether this machine's stored library setup can be read. When it is " \
                                      "unreadable, adding or removing a library is refused until reset clears it.",
                      :refuses => %w[library.setup_unavailable],
                      :params => Library.object({}), :result => setup_state, :examples => [{}]) do |_request|
          { "state" => Setup.state }
        end
        feature.snapshot_section("ph_composer.library.provider_setup", :query => "#{PREFIX}.setup_state")
        feature.setup_command("#{PREFIX}.reset",
                              :description => "Clear this machine's library setup when setup_state reports it " \
                                              "unreadable. A readable setup is left unchanged.",
                              :refuses => %w[library.setup_unavailable],
                              :params => Library.object({}), :result => result, :examples => [{}]) do |_request|
          value = Setup.reset
          refresh_sessions
          value
        end
      end

      def setup_state
        Library.object({ "state" => Library.described({ "type" => "string", "enum" => %w[readable unreadable] },
                                                      "unreadable when the stored setup fails to parse or " \
                                                      "validate; nothing stored yet is readable.") })
      end

      # A completed add names the library it added, which is not among the ids `before` it; any other
      # outcome shows its own message.
      def menu_message(outcome, before)
        added = outcome["status"] == "completed" &&
                outcome.fetch("value").find { |row| !before.include?(row.fetch("id")) }
        added ? "Added library #{added.fetch('label')}." : outcome.fetch("message")
      end

      # The native menu is one client per session, as the panel is.
      def menu_context(session)
        session.feature_state(:library_menu_context) do
          API.connect(:session_id => session.id, :capabilities => %w[read setup])
        end
      end

      def kind_adapters(registry)
        adapters = registry.library_kinds.values.map(&:adapter)
        [adapters.map(&:wire_kind), ->(kind) { adapters.find { |adapter| adapter.wire_kind == kind } }]
      end

      # `fallback` is the label of the approved location the path came from, if any.
      def add_path(path, kinds:, adapters:, fallback: nil)
        fallback ||= "Library folder #{Setup.load.length + 1}"
        label = public_label(path, :kinds => kinds, :adapters => adapters, :fallback => fallback)
        Setup.add_file(:id => Records::Identity.mint("library"), :label => label, :path => path)
      rescue SystemCallError, IOError, EncodingError
        raise Error.new("library.file_unreadable",
                        "The selected library file or folder could not be read."), :cause => nil
      end

      # A library file's own name, or for a folder that does not hold exactly one library, `fallback`:
      # never the folder's name, which a public result must not carry.
      def public_label(path, kinds:, adapters:, fallback:)
        if File.directory?(path)
          # FileProvider owns aggregate bounds and skips unrelated malformed candidate files.
          provider = FileProvider.new(:id => "validation", :label => "Library", :path => path,
                                      :kinds => kinds, :adapters => adapters)
          provider.list(kinds.first) unless kinds.empty?
          files = Dir.children(path).select { |name|
            File.extname(name).downcase == ".json" &&
              File.file?(File.join(path, name))
          }
          return fallback unless files.length == 1

          begin
            return file_label(File.join(path, files.first), adapters)
          rescue Error
            return fallback
          end
        end
        file_label(path, adapters)
      end

      def file_label(path, adapters)
        text = File.open(path, "rb") { |file| file.read(LibraryFile::MAX_BYTES + 1) }
        LibraryFile.parse(text, :adapters => adapters).fetch("library").fetch("name")
      end

      def refresh_sessions
        Sessions.all.each(&:request_refresh)
      end
    end
  end
end
