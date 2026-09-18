# frozen_string_literal: true

# The contributor walkthrough (planning/refactor/phase-zero/CONTRACTS.md) as a script: two clients
# drive the example feature through PhComposer::API with the panel closed. Every step records what
# happened and whether it is what the contract says. Run it against an open Model:
#
#   ExampleWalkthrough.run                      # the active Model's session
#   ExampleWalkthrough.run(session_id: "...")   # any session discovery lists
#
# It writes records into that Model, each change one Undo step.
module ExampleWalkthrough
  API = PhComposer::API
  PART = ExampleFoundation::PART
  ID = ExampleFoundation::ID

  module_function

  def run(session_id: nil)
    found = API.discover
    session = session_id || found.fetch("sessions").find { |row| row.fetch("active") }&.fetch("id")
    raise ArgumentError, "No open Model session." unless session

    steps = []
    first = API.connect(:session_id => session)
    second = API.connect(:session_id => session)

    created = invoke(first, "#{ID}.create_parts", create_params, 1, revision(first))
    sill, head = created.dig("value", "part_ids")
    steps << step("create", created, created["effect"] == "committed")

    read = parts(first, [sill])
    read_revision = read.fetch("revision")
    steps << step("read", read, read.dig("value", "records", 0, "values", "length_mm") == 1200)

    edit = { "edits" => [{
      "id" => sill, "values" => { "length_mm" => 950 }, "expected_values" => { "length_mm" => 1200 },
      "user_data" => { "example_org" => { "review_status" => "needs_site_check" } },
      "review" => { "review_status" => "draft", "checked_against" => head }
    }] }
    updated = invoke(first, "#{ID}.update_parts", edit, 2, read_revision)
    steps << step("update", updated, updated["effect"] == "committed" && updated["revision"] > read_revision)

    back = parts(first, [sill]).dig("value", "records", 0)
    steps << step("read back", updated, back.dig("values", "length_mm") == 950 &&
                                        back.dig("user_data", "example_org", "review_status") == "needs_site_check")

    stale = invoke(second, "#{ID}.update_parts", { "edits" => [{ "id" => sill, "values" => { "length_mm" => 800 } }] },
                   1, read_revision)
    unchanged = parts(first, [sill]).dig("value", "records", 0, "values", "length_mm") == 950
    steps << step("stale second client", stale, stale["code"] == "revision.stale" && unchanged)

    retried = invoke(first, "#{ID}.update_parts", edit, 2, read_revision)
    steps << step("retry", retried, retried == updated)

    duplicated = invoke(first, "#{ID}.duplicate_parts", { "ids" => [sill, head] }, 3, revision(first))
    mapping = duplicated.dig("value", "mapping") || {}
    copy = parts(first, [mapping[sill]].compact).dig("value", "records", 0) || {}
    remapped = copy.dig("extension_data", ExampleFoundation::REVIEW, "payload", "checked_against") == mapping[head]
    shared = copy.dig("values", "definition_id") == back.dig("values", "definition_id")
    steps << step("duplicate", duplicated, remapped && shared && copy["user_data"] == back["user_data"])

    summary = API.query(:context => first, :name => "#{ID}.summary")
    steps << step("summary", summary, summary.dig("value", "parts") >= 4)

    { "session" => session, "passed" => steps.all? { |row| row["passed"] }, "steps" => steps }
  end

  def create_params
    { "definition_label" => "Frame",
      "parts" => [{ "label" => "Sill", "length_mm" => 1200 }, { "label" => "Head", "length_mm" => 1200 }] }
  end

  def invoke(context, name, params, sequence, expected_revision)
    API.invoke(:context => context, :name => name, :params => params,
               :request => { "sequence" => sequence, "expected_revision" => expected_revision })
  end

  def parts(context, ids)
    API.query(:context => context, :name => "ph_composer.records.list", :params => { "kind" => PART, "ids" => ids })
  end

  def revision(context)
    API.query(:context => context, :name => "#{ID}.summary").fetch("revision")
  end

  def step(name, outcome, passed)
    { "step" => name, "status" => outcome["status"], "code" => outcome["code"], "effect" => outcome["effect"],
      "revision" => outcome["revision"], "passed" => passed ? true : false }
  end
end
