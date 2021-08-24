# TODO(spox): why do we need this?!
require_relative "../util.rb"

module VagrantPlugins
  module CommandServe
    module Client
      class Terminal
        extend Util::Connector

        attr_reader :broker
        attr_reader :client
        attr_reader :proto

        # @params [String] endpoint for the core service
        def initialize(server_endpoint, proto, broker=nil)
          @client = SDK::TerminalUIService::Stub.new(server_endpoint, :this_channel_is_insecure)
          @broker = broker
          @proto = proto
        end

        def self.load(raw_terminal, broker:)
          t = raw_terminal.is_a?(String) ? SDK::Args::TerminalUI.decode(raw_terminal) : raw_terminal
          self.new(connect(proto: t, broker: broker), t, broker)
        end

        # @param [Array] lines Lines to print
        def output(lines, **opts)
          args = {
            lines: lines,
            disable_new_line: !opts[:new_line],
            style: :error,
          }
          case opts[:style]
          when :detail, :info, :output
            args[:style] = SDK::TerminalUI::OutputRequest::Style::INFO
          when :warn
            args[:style] = SDK::TerminalUI::OutputRequest::Style::WARNING
          when :error
            args[:style] = SDK::TerminalUI::OutputRequest::Style::ERROR
          when :success
            args[:style] = SDK::TerminalUI::OutputRequest::Style::SUCCESS
          end

          client.output(req = SDK::TerminalUI::OutputRequest.new(**args))
        end
      end
    end
  end
end
