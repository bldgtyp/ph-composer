# frozen_string_literal: true

module PhComposer
  module Windows
    FEATURE_ID = "ph_composer.windows"
    FRAME_KIND = "#{FEATURE_ID}.frame"
    GLAZING_KIND = "#{FEATURE_ID}.glazing"
    PSI_INSTALL_KIND = "#{FEATURE_ID}.psi_install_type"
    TYPE_KIND = "#{FEATURE_ID}.window_type"
    Fields = Records::AuthoringFields

    # Products are model-owned definitions. Signed junction values and zero U-values are authored
    # exactly; missing values remain absent or null until the user supplies them.
    module Products
      SPECS = {
        "frames" => { :id => FRAME_KIND, :prefix => "frm", :label => "Frame",
                :text => %w[manufacturer product_code position operation],
                :numbers => { "width_m" => ["m", 0], "uf_w_m2k" => ["W/m2K", 0],
                "psi_g_w_mk" => ["W/mK", nil] } },
        "glazings" => { :id => GLAZING_KIND, :prefix => "glz", :label => "Glazing",
                :text => %w[manufacturer product_code description],
                :numbers => { "ug_w_m2k" => ["W/m2K", 0], "g_value" => ["fraction", 0, 1] } },
        "psi_install_types" => { :id => PSI_INSTALL_KIND, :prefix => "psi", :label => "Psi-Install Type",
                :text => [], :numbers => { "psi_w_mk" => ["W/mK", nil] } }
      }.freeze

      module_function

      def numeric_schema(spec)
        shape = { "type" => %w[number null], "x-unit" => spec.first }
        shape["minimum"] = spec[1] unless spec[1].nil?
        shape["maximum"] = spec[2] unless spec[2].nil?
        shape
      end

      def fields(spec)
        result = Fields.common + spec.fetch(:text).map { |key| Fields.field(key, { "type" => "string" }) }
        result += spec.fetch(:numbers).map { |key, shape| Fields.field(key, numeric_schema(shape)) }
        result << Fields.field("color", { "type" => "string" }) unless spec.fetch(:id) == PSI_INSTALL_KIND
        result
      end

      KINDS = SPECS.to_h do |collection, spec|
        authored = fields(spec)
        snapshot_schema = Fields.source_snapshot_schema(authored)
        authored.find { |field| field.key == "source" }.schema.fetch("properties")["snapshot"] = snapshot_schema
        kind = Records::RecordKind.new(
          :id => spec.fetch(:id), :label => spec.fetch(:label), :schema_version => 1,
          :id_prefix => spec.fetch(:prefix), :fields => authored,
          :validate => ->(values) {
 Fields.problems(values) + Fields.source_problems(values["source"], snapshot_schema) }
        )
        [collection, kind]
      end.freeze

      def defaults(collection, values)
        result = SPECS.fetch(collection).fetch(:text).to_h { |key| [key, ""] }
        result["color"] = "#ffffff" unless collection == "psi_install_types"
        result.merge(Fields.defaults(values))
      end
    end
  end
end
