# frozen_string_literal: true

module PhComposer
  # Who is calling, against which Model session, under which API major (context/CONTRACTS.md, "Public
  # interface"). A caller receives its context from `API.connect`; the handle it carries is looked up
  # in the session, so the context grants nothing by itself and a serialized copy cannot add a
  # capability.
  OperationContext = Struct.new(:api_major, :session_id, :caller, keyword_init: true)
end
