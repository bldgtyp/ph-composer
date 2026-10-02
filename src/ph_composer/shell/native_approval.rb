# frozen_string_literal: true

module PhComposer
  # How a native client, the panel or a menu, asks the user for the location a setup command or file
  # export declares (Declarations::Approval) and then calls it. The dialogs live here, outside every
  # handler, so a scripted caller of the same operation is refused at once instead of blocking
  # SketchUp on a dialog nobody is watching (context/AGENT_INTERFACE.md, "Host lifecycle"). A
  # declaration without an approval runs as the public API would run it.
  module NativeApproval
    # The location the user chose and, for a save destination that already exists, whether they agreed
    # to replace it. It never enters params, a result or a log.
    Granted = Struct.new(:path, :replace, keyword_init: true) do
      def inspect
        "#<#{self.class.name}>"
      end
      alias_method :to_s, :inspect

      # Printing or serializing an approval never shows its path; read `path` explicitly.
      def to_h
        { "replace" => replace }
      end
      alias_method :to_a, :to_h
    end

    NOUNS = { "save_file" => "destination file", "open_file" => "file", "open_folder" => "folder" }.freeze

    module_function

    def setup(context, name, params)
      call(context, Registry.current.setup_commands[name]) do |approval|
        Dispatch.new.setup(context, name, params, :approval => approval)
      end
    end

    def file_export(context, name, params)
      call(context, Registry.current.file_exports[name]) do |approval|
        Dispatch.new.file_export(context, name, params, :approval => approval)
      end
    end

    def noun(approval)
      NOUNS.fetch(approval.kind)
    end

    # The dispatch outcome, or a cancellation when the user dismissed a dialog. An unknown name or a
    # closed session opens no dialog and is dispatch's to refuse; grants and a busy session are
    # checked by dispatch after the dialog, which is why only a client holding the grant calls this.
    def call(context, declaration)
      approval = declaration&.approval
      session = context.is_a?(OperationContext) && Sessions.find(context.session_id)
      return yield(nil) unless approval && session

      granted = ask(approval, session.model)
      return cancelled(session) unless granted

      yield granted
    end

    # A Granted from the native dialog for `approval`, or nil when the user cancelled it.
    def ask(approval, model)
      case approval.kind
      when "save_file" then save_destination(approval, model)
      when "open_file" then present(UI.openpanel(approval.title, nil, approval.filter || "*.*"))
      when "open_folder" then present(UI.select_directory(:title => approval.title))
      end
    end

    def save_destination(approval, model)
      directory = model.path.to_s.empty? ? nil : File.dirname(model.path)
      path = UI.savepanel(approval.title, directory, approval.default_name)
      return nil if path.nil?

      replace = File.exist?(path)
      return nil if replace && UI.messagebox("Replace the existing file?", MB_YESNO) != IDYES

      Granted.new(:path => path, :replace => replace)
    end

    def present(path)
      path && Granted.new(:path => path, :replace => false)
    end

    def cancelled(session)
      Outcome.build("cancelled", "request.cancelled", "Cancelled. Nothing changed.", "none", session.revision)
    end
    private_class_method :call, :ask, :save_destination, :present, :cancelled
  end
end
