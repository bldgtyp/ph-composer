# frozen_string_literal: true

module PhComposer
  # The one result shape every public query and operation answers with (context/CONTRACTS.md,
  # "Outcomes and codes"):
  #
  #   {"status": "completed", "code": "ok", "message": "...", "effect": "committed", "revision": 7,
  #    "value": {...}, "affected": [{"kind": "...", "id": "...", "change": "updated"}],
  #    "findings": [...], "detail": null}
  #
  # `status` says how the request ended, `effect` what happened to the Model, `code` why. Fields are
  # nested and named; a handler's value never merges into the envelope.
  module Outcome
    NOTHING_WRITTEN = "Nothing was written."
    ROLLED_BACK = "The change could not be completed. No changes were retained."
    # The abort ran, but the unchanged-data check failed or could not run, so the message cannot
    # confirm that nothing changed.
    UNVERIFIED = "The change could not be completed, and PH-Composer could not confirm that the Model " \
                 "is unchanged. Check the Model before continuing."

    module_function

    def completed(revision:, value: nil, effect: "none", affected: [], findings: [], proposal_digest: nil,
                  message: "Done.")
      build("completed", "ok", message, effect, revision, :value => value, :affected => affected,
            :findings => findings, :proposal_digest => proposal_digest)
    end

    # A request turned away before anything was written. `mutation` adds the sentence that tells a
    # user the Model did not change.
    def refused(code, message, revision:, status: "refused", mutation: false, findings: [], detail: nil)
      text = mutation ? "#{message} #{NOTHING_WRITTEN}" : message
      build(status, code, text, "none", revision, :findings => findings, :detail => detail)
    end

    def failed(effect:, revision:, reason: nil)
      message = effect == "rolled_back" ? ROLLED_BACK : UNVERIFIED
      code = effect == "rolled_back" ? "operation.failed" : "operation.rollback_unverified"
      # A declared domain failure remains actionable even when it arose during a native cut.
      # Keep rollback certainty separate; never expose an unexpected exception's message.
      detail = reason && { "cause" => reason.code, "detail" => DeepCopy.call(reason.detail) }
      message = "#{reason.message} #{message}" if reason
      build("failed", code, message, effect, revision, :detail => detail)
    end

    def build(status, code, message, effect, revision, value: nil, affected: [], findings: [], detail: nil,
              proposal_digest: nil)
      {
        "status" => status, "code" => code, "message" => message, "effect" => effect, "revision" => revision,
        "value" => value, "affected" => affected, "findings" => findings, "detail" => detail,
        "proposal_digest" => proposal_digest
      }
    end
  end
end
