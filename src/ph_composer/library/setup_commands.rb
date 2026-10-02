# frozen_string_literal: true

require_relative "setup"

module PhComposer
  module Library
    # Native file pickers alone see transport addresses. Public views return configured labels.
    module SetupCommands
      PREFIX = "ph_composer.library.providers"
      module_function

      def install(feature)
        result = Schemas.list(Schemas.object({ "id" => Schemas::TEXT, "label" => Schemas::TEXT,
                                              "provider_kind" => Schemas::TEXT }))
        %w[add_file add_folder].each do |verb|
          feature.view_command("#{PREFIX}.#{verb}", :description => "Configure a library through a native picker.",
                               :params => Library.object({}), :result => result, :examples => [{}]) do |request|
            path = if verb == "add_file"
                     UI.openpanel("Add library file", nil, "*.json")
                   else
                     UI.select_directory(:title => "Add library folder")
                   end
            kinds, adapters = kind_adapters(request.registry)
            value = add_path(path, :kinds => kinds, :adapters => adapters)
            refresh_sessions if path
            value
          end
          feature.menu_item("#{PREFIX}.#{verb}_menu", :label => verb == "add_file" ? "Add Library File…" :
                            "Add Library Folder…", :menu => "Libraries",
                            :available => ->(_read) { false }) do |session|
            outcome = API.view(:context => menu_context(session), :name => "#{PREFIX}.#{verb}", :params => {})
            session.notice(outcome.fetch("message"), :tone => outcome["status"] == "completed" ? :info : :warning)
          end
        end
        feature.view_command("#{PREFIX}.remove", :description => "Remove a configured library from this machine.",
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
        session.feature_state(:library_menu_context) { API.connect(:session_id => session.id) }
      end

      def kind_adapters(registry)
        adapters = registry.library_kinds.values.map(&:adapter)
        [adapters.map(&:wire_kind), ->(kind) { adapters.find { |adapter| adapter.wire_kind == kind } }]
      end

      def add_path(path, kinds:, adapters:)
        return Setup.providers if path.nil?

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
