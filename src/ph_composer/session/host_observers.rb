# frozen_string_literal: true

module PhComposer
  # Adapters from SketchUp's observer callbacks to session host events. They record the event and
  # return; deferred work mutates (context/TECH_STACK.md "Observers report; deferred work mutates").
  # Features subscribe to the events in their `install`; nothing here names a feature.
  module HostObservers
    class AppObserver < Sketchup::AppObserver
      def onNewModel(model)
        Sessions.for(model)
      end

      def onOpenModel(model)
        Sessions.for(model)
      end

      def onActivateModel(model)
        session = Sessions.for(model)
        session.host_event(:model_activated)
        Sessions.notify_refresh(session)
      end
    end

    class ModelObserver < Sketchup::ModelObserver
      def onTransactionCommit(model)
        Sessions.for(model).host_event(:transaction_committed)
      end

      def onTransactionUndo(model)
        Sessions.for(model).host_event(:transaction_undone)
      end

      def onTransactionRedo(model)
        Sessions.for(model).host_event(:transaction_redone)
      end

      def onActivePathChanged(model)
        Sessions.for(model).host_event(:active_path_changed)
      end

      def onPreSaveModel(model)
        Sessions.for(model).host_event(:pre_save)
      end

      def onSaveModel(model)
        Sessions.for(model).host_event(:post_save)
      end
    end

    class SelectionObserver < Sketchup::SelectionObserver
      def onSelectionBulkChange(selection)
        selection_changed(selection)
      end

      def onSelectionCleared(selection)
        selection_changed(selection)
      end

      def onSelectionAdded(selection, _entity)
        selection_changed(selection)
      end

      def onSelectionRemoved(selection, _entity)
        selection_changed(selection)
      end

      private

      def selection_changed(selection)
        model = selection.respond_to?(:model) ? selection.model : Sketchup.active_model
        session = model && Sessions.for(model)
        return unless session

        session.host_event(:selection_changed)
        session.request_refresh
      end
    end
  end
end
