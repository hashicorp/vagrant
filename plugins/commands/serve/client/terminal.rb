# TODO(spox): why do we need this?!
require_relative "../util.rb"

module VagrantPlugins
  module CommandServe
    module Client
      class Terminal
        extend Util::Connector

        attr_reader :client

        # @params [String] endpoint for the core service
        def initialize(server_endpoint)
          @client = SDK::TerminalUIService::Stub.new(server_endpoint, :this_channel_is_insecure)
        end

        def self.load(raw_terminal, broker:)
          t = SDK::Args::TerminalUI.decode(raw_terminal)
          self.new(connect(proto: t, broker: broker))
        end

        # @params [Array] the content to print
        def output(content)
          req = SDK::TerminalUI::OutputRequest.new(
            lines: content
          )
          client.output(req)
        end
      end
    end
  end
end
