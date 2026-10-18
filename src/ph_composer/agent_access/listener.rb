# frozen_string_literal: true

module PhComposer
  module AgentAccess
    # Whether the loopback Server runs, and on which port. It runs while at least one agent token is
    # live: the first issued token starts it, the last revoke stops it, and every token store write hands
    # it the new snapshot. Main thread only.
    module Listener
      PORT_KEY = "agent_access.port"
      PORTS = (1024..65_535).freeze

      # Builds the Server for a port. The offline suite replaces it so no test binds the agent port.
      DEFAULT_FACTORY = lambda do |port|
        Server.new(:port => port, :protocol => MCP, :executor => Executor.new(:tools => Tools::TABLE))
      end

      class << self
        attr_writer :server_factory

        def refresh
          snapshot = Tokens.snapshot
          return stop if snapshot.empty?

          start unless @server
          @server&.tokens = snapshot
        end

        def stop
          @server&.stop
          @server = nil
          @failure = nil
        end

        # The dialog's status line: listening on a port, stopped with no live token, or unable to bind.
        def status
          return { "state" => "listening", "port" => @server.port } if @server
          return { "state" => "unavailable", "port" => port, "message" => @failure } if @failure

          { "state" => "stopped", "port" => port }
        end

        # The port from SketchUp's defaults, or the default port when none valid is stored.
        def port
          stored = Sketchup.read_default(Preferences::SECTION, PORT_KEY, Server::DEFAULT_PORT)
          stored.is_a?(Integer) && PORTS.cover?(stored) ? stored : Server::DEFAULT_PORT
        end

        def server
          @server
        end

        # Stores a new port and moves a running or failed listener onto it. Raises CodedError for a port
        # outside 1024 to 65535.
        def port=(value)
          unless value.is_a?(Integer) && PORTS.cover?(value)
            raise CodedError.new("params.invalid", "A port is a whole number from #{PORTS.min} to #{PORTS.max}.")
          end

          Sketchup.write_default(Preferences::SECTION, PORT_KEY, value)
          stop
          refresh
        end

        # Each token's latest call since SketchUp started, by token id: its time and how it ended.
        def last_calls
          return {} unless @server

          @server.snapshot.fetch("recent").each_with_object({}) do |row, calls|
            calls[row["token"]] = { "at" => row["at"], "status" => row["error"] ? "error" : row["status"].to_s }
          end
        end

        private

        def start
          @failure = nil
          @server = (@server_factory || DEFAULT_FACTORY).call(port).start
          Diagnostics.log("agent_access_listening", "status" => "ok")
        rescue SystemCallError => error
          @server = nil
          @failure = error.is_a?(Errno::EADDRINUSE) ? "Port #{port} is in use by another program." : error.message
          Diagnostics.log("agent_access_listening", "status" => "failed", "error_class" => error.class.name)
        end
      end
    end
  end
end
