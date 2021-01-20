module VagrantPlugins
  module CommandServe
    module Client
      class TerminalClient

        # @params [String] endpoint for the core service 
        def initialize(server_endpoint)
          @client = Hashicorp::Vagrant::Sdk::TerminalUIService::Stub.new(server_endpoint, :this_channel_is_insecure)
        end

        def self.terminal_arg_to_terminal_ui(raw_terminal)
          terminal_arg = Hashicorp::Vagrant::Sdk::Args::TerminalUI.decode(raw_terminal)
          # TODO (sophia): this should have an option to not be a unix socket
          addr = "unix:" + terminal_arg.addr
          self.new(addr)
        end

        # @params [Array] the content to print
        def output(content)
          req = Hashicorp::Vagrant::Sdk::TerminalUI::OutputRequest.new(
            lines: content
          )
          @client.output(req)
        end
      end
    end
  end
end
