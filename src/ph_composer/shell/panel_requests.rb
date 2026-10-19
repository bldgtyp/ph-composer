# frozen_string_literal: true

module PhComposer
  # The action request ids the shown panel page has sent, per session, each with the mutation sequence it
  # was given, so the page can ask what became of one whose result it lost (`action.status`).
  #
  # Page messages arrive in order, so an id this page never sent through here was never received, and
  # nothing ran. That holds only while every id is still held: once one has been dropped to keep the map
  # bounded, a missing id may be one that ran, and the session says so. A newly loaded page numbers its
  # ids from the start again, so `reset` runs when a page reports ready.
  module PanelRequests
    MAX_TRACKED = 64

    module_function

    def track(session, request_id, sequence)
      held = for_session(session)
      held[:ids][request_id.to_s] = sequence
      return if held[:ids].length <= MAX_TRACKED

      held[:ids].delete(held[:ids].keys.first)
      held[:forgotten] = true
    end

    # The sequence the request was given, or nil when the host does not hold it.
    def sequence(session, request_id)
      for_session(session)[:ids][request_id.to_s]
    end

    # Whether an id this page sent may have been dropped, so a missing one cannot be called unreceived.
    def forgotten?(session)
      for_session(session)[:forgotten]
    end

    def for_session(session)
      (@sessions ||= {}).delete_if { |id, _held| Sessions.find(id).nil? }
      @sessions[session.id] ||= { :ids => {}, :forgotten => false }
    end

    def reset
      @sessions = {}
    end
  end

  on_reset("panel_requests") { PanelRequests.reset }
end
