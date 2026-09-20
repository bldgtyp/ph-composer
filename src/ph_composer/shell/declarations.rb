# frozen_string_literal: true

module PhComposer
  # What a feature declares in its `install(registry)` (CONTRACTS.md C1). Each is a plain value; the
  # registry validates a feature's declarations together before any becomes available.
  module Declarations
    # The contract major every declaration here belongs to. A feature declares the major it was
    # written against; an incompatible major is refused at registration.
    CONTRACT_VERSION = 1

    Feature = Struct.new(:id, :contract_version, :requires, keyword_init: true)

    # A bounded read. `handler` is `->(request) { value }`; it must not write to the Model.
    Query = Struct.new(:name, :owner, :description, :params, :result, :examples, :handler, keyword_init: true)

    # A validated Model change. `handler` is `->(request, changes) { value }`: it proposes record
    # writes into `changes` (a Records::ChangeSet) and never writes itself. The dispatcher applies
    # the proposal as one native operation named `undo_name`. `confirmation` is the policy every
    # client must satisfy before the operation opens; Phase 0 supports only "none".
    Action = Struct.new(
      :name, :owner, :description, :params, :result, :examples, :undo_name, :side_effects, :confirmation, :handler,
      keyword_init: true
    )

    # A panel snapshot section: the result of one registered query, under the section's name.
    SnapshotSection = Struct.new(:name, :owner, :query, :params, keyword_init: true)

    HostEventSubscription = Struct.new(:owner, :kind, :handler, keyword_init: true)

    # One section of the export extraction (CONTRACTS.md C6). `contract` is `->(reader) { [record, ...] }`:
    # it reads through an Export::RecordReader, which applies the metadata and extension-data rules, and
    # never writes. `name` is the section id the translation package reads, at `section_version`.
    # `result` declares the top-level result fields the feature's translation adds, in Export::Privacy's
    # schema form; `report` is `->(result, display_units) { [html_section, ...] }` over those fields.
    ExportContributor = Struct.new(:name, :owner, :section_version, :contract, :result, :report, keyword_init: true)

    # One Colour-by mode: the fourth contribution seam (face-assignment PRD "Colour-by"). `projection`
    # is `->(model) { [ColourBy::Entry, ...] }`: a pure read of the feature's own entities, their
    # world transforms and the value each one carries. `colours` is `->(value) { [r, g, b] }`, nil for
    # a value the mode cannot colour, which the service draws as incomplete. `entity_kind` is open
    # prose naming what the mode paints; the service tessellates whatever entity an entry carries.
    # `sort` is an optional `->(row) { key }` over legend rows.
    ColourMode = Struct.new(:name, :owner, :label, :entity_kind, :colours, :sort, :projection, keyword_init: true)
    ProposalParticipant = Struct.new(:name, :owner, :handler, keyword_init: true)

    # One registration problem. `subject` is the declaration it concerns; `dependency` names what it
    # needed, when that is the problem.
    Diagnostic = Struct.new(:code, :owner, :subject, :message, :dependency, keyword_init: true) do
      def to_s
        "#{code}: #{message}"
      end
    end
  end

  # A feature, or a batch of features, could not be registered. Nothing in the batch was published.
  class RegistrationError < InternalError
    attr_reader :diagnostics

    def initialize(diagnostics)
      @diagnostics = diagnostics
      super("Registration refused:\n  " + diagnostics.map(&:to_s).join("\n  "))
    end
  end
end
