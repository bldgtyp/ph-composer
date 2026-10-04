# frozen_string_literal: true

require_relative "export_workflow"

module PhComposer
  module Library
    module ExportRegistration
      module_function

      def params
        text = { "type" => "string", "minLength" => 1 }
        selected = Library.object({ "record_kind" => text, "id" => text })
        Library.object({
          "scope" => Library.described({ "type" => "string", "enum" => %w[all selected] },
                                       "all, the default, takes every supported local definition; selected takes " \
                                       "only records."),
          "identity" => Library.described({ "type" => "string", "enum" => %w[new update] },
                                          "new, the default, gives the file a new library id; update keeps the id " \
                                          "of the library file being replaced."),
          "kinds" => Library.described({ "type" => "array", "items" => text, "minItems" => 1 },
                                       "Limit the export to these library kinds, such as materials."),
          "records" => Library.described({ "type" => "array", "items" => selected, "minItems" => 1 },
                                         "With scope selected: the records to export, each by record kind and id."),
          "library_name" => Library.described(text, "The library name written into the file. Defaults to Model " \
                                                    "library, or to the replaced file's name for update."),
          "expected_revision" => Library.described({ "type" => "integer", "minimum" => 0 },
                                                   "The Model revision export_preview reported; refused if the " \
                                                   "Model changed since."),
          "projection_digest" => Library.described(text, "The projection_digest export_preview reported; refused " \
                                                         "if what would be written differs. Required to replace a " \
                                                         "file at an approved location.")
        }, :optional => %w[scope identity kinds records library_name expected_revision projection_digest])
      end

      def summary_fields
        text = { "type" => "string", "minLength" => 1 }
        label = Library.described(text, "The registered record kind's label, for display; kind and record_kind " \
                                        "stay the identifiers.")
        counted = Library.object({ "kind" => text, "record_kind_label" => label,
                                   "count" => { "type" => "integer", "minimum" => 0 } })
        omitted = Library.object({ "record_kind" => text, "record_kind_label" => label, "id" => text,
                                   "fields" => { "type" => "array", "items" => text }, "reason" => text },
                                 :optional => ["id"])
        { "kinds" => { "type" => "array", "items" => counted },
          "omissions" => { "type" => "array", "items" => omitted } }
      end

      def install(feature)
        shape = Library.object(summary_fields.merge("library_id" => Library::TEXT, "library_name" => Library::TEXT,
                                                    "identity" => { "type" => "string", "enum" => %w[new update] },
                                                    "written" => { "type" => "boolean" }))
        feature.file_export("#{FEATURE_ID}.export_file",
                            :description => "Write local definitions to a library file the user chooses in the " \
                                            "native save dialog; export_preview shows what it will hold.",
                            :refuses => Refuses::EXPORT_FILE,
                            :params => params, :result => shape, :approval => ExportWorkflow::APPROVAL,
                            :precondition => ExportWorkflow.method(:precondition),
                            :examples => [{}, { "scope" => "selected", "records" => [
                                                                         { "record_kind" => "example_parts",
                                                                           "id" => "part_AAAAAAAAAAAA" }
                                                                       ],
                                                "identity" => "new" }]) do |request|
          ExportWorkflow.run(request)
        end
        install_preview(feature)
      end

      def install_preview(feature)
        destination = Library.described(
          Library.object({ "exists" => { "type" => "boolean" }, "state" => { "type" => %w[string null] } }),
          "With location: whether the approved destination holds a file, and its state. Pass state as the " \
          "location's expected_destination to replace it."
        )
        preview_shape = Library.object(summary_fields.merge("projection_digest" => Library::TEXT,
                                                            "revision" => { "type" => "integer", "minimum" => 0 },
                                                            "destination" => destination),
                                       :optional => ["destination"])
        location = Library.described({ "type" => "string", "minLength" => 1 },
                                     "The id of an approved save destination, to report what it holds now.")
        preview_params = Library.object(params.fetch("properties").slice("scope", "kinds", "records")
                                              .merge("location" => location),
                                        :optional => %w[scope kinds records location])
        feature.query("#{FEATURE_ID}.export_preview",
                      :description => "Review local library export counts and omissions.",
                      :refuses => Refuses::EXPORT_PREVIEW,
                      :params => preview_params, :result => preview_shape, :examples => [{}]) do |request|
          projection = ExportProjection.build(request)
          summary = ExportProjection.summary(projection, request.registry)
          value = summary.merge("projection_digest" => projection.fetch("projection_digest"),
                                "revision" => request.session.revision)
          next value unless request.params.key?("location")

          value.merge("destination" => ApprovedLocations.observe(request.params["location"]) do |path|
            FileWriter.state(path)
          end)
        end
      end
    end
  end
end
