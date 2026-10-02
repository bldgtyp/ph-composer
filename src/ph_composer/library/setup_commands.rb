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
      module_function

      def install(feature)
        result = Schemas.list(Schemas.object({ "id" => Schemas::TEXT, "label" => Schemas::TEXT,
                                              "provider_kind" => Schemas::TEXT }))
        ADDS.each do |verb, approval|
          feature.setup_command("#{PREFIX}.#{verb}", :description => DESCRIPTIONS.fetch(verb),
                                :params => Library.object({}), :result => result, :examples => [{}],
                                :approval => approval) do |request|
            kinds, adapters = kind_adapters(request.registry)
            value = add_path(request.approval.path, :kinds => kinds, :adapters => adapters)
            refresh_sessions
            value
          end
          feature.menu_item("#{PREFIX}.#{verb}_menu", :label => verb == "add_file" ? "Add Library File…" :
                            "Add Library Folder…", :menu => "Libraries",
                            :available => ->(_read) { false }) do |session|
            outcome = NativeApproval.setup(menu_context(session), "#{PREFIX}.#{verb}", {})
            next if outcome["status"] == "cancelled"

            session.notice(outcome.fetch("message"), :tone => outcome["status"] == "completed" ? :info : :warning)
          end
        end
        feature.setup_command("#{PREFIX}.remove", :description => "Remove a configured library from this machine.",
                             :params => Library.object({ "provider_id" => Library::TEXT }), :result => result,
                             :examples => [{ "provider_id" => "example" }]) do |request|
          id = request.params.fetch("provider_id")
          value = Setup.remove(id)
          refresh_sessions
          value
        end
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

      def add_path(path, kinds:, adapters:)
        label = public_label(path, :kinds => kinds, :adapters => adapters)
        Setup.add_file(:id => Records::Identity.mint("library"), :label => label, :path => path)
      rescue SystemCallError, IOError, EncodingError
        raise Error.new("library.file_unreadable",
                        "The selected library file or folder could not be read."), :cause => nil
      end

      def public_label(path, kinds:, adapters:)
        if File.directory?(path)
          # FileProvider owns aggregate bounds and skips unrelated malformed candidate files.
          provider = FileProvider.new(:id => "validation", :label => "Library", :path => path,
                                      :kinds => kinds, :adapters => adapters)
          provider.list(kinds.first) unless kinds.empty?
          files = Dir.children(path).select { |name| File.extname(name).downcase == ".json" &&
                                                    File.file?(File.join(path, name)) }
          return File.basename(path) unless files.length == 1

          begin
            return file_label(File.join(path, files.first), adapters)
          rescue Error
            return File.basename(path)
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
