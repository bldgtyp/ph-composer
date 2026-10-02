# frozen_string_literal: true

module PhComposer
  module Zones
    # Native selection is a client of the same Make Zone action the panel and scripts use.
    module ZoneMenu
      module_function

      def install(feature)
        feature.menu_item("#{FEATURE_ID}.make_menu", :label => "Make Zone", :menu => EXTENSION_NAME,
                                                     :available => ->(read) {
                                                                     !Zones.make_target(read.model).nil?
                                                                   }) do |session|
          session.feature_state(:zones_menu) { Client.new(session) }.make
        end
      end

      class Client
        def initialize(session)
          @session = session
          @context = API.connect(:session_id => session.id)
          @sequence = 0
        end

        def make
          target = API.query(:context => @context, :name => "#{FEATURE_ID}.list",
                             :params => { "fields" => [], "limit" => 1 })
          return show(target) unless target["status"] == "completed"

          params = target.fetch("value").fetch("make_zone")
          unless params
            message = "Select one Group or loose Faces and Edges first. Nothing was written."
            @session.notice(message, :tone => :warning)
            Sketchup.status_text = message
            return
          end

          @sequence += 1
          result = API.invoke(:context => @context, :name => "#{FEATURE_ID}.make", :params => params,
                              :request => { "sequence" => @sequence,
                                            "expected_revision" => target.fetch("revision") })
          show(result)
        end

        private

        def show(result)
          @session.notice(result.fetch("message"), :tone => result["status"] == "completed" ? :info : :warning)
          Sketchup.status_text = result.fetch("message")
          result
        end
      end
    end
  end
end
