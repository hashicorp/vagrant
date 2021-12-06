require "log4r"

module Vagrant
  module Plugin
    module Remote
      # This class maintains a list of all the registered plugins as well
      # as provides methods that allow querying all registered components of
      # those plugins as a single unit.
      class Manager < Vagrant::Plugin::V2::Manager
        attr_reader :registered

        def initialize()
          @logger = Log4r::Logger.new("vagrant::plugin::remote::manager")
          # Copy in local Ruby registered plugins
          @registered = Vagrant.plugin("2").manager.registered
        end

        # Registers remote plugins provided from the client
        #
        # @param [VagrantPlugin::Command::Serve::Client::Basis]
        def register_remote_plugins(client)
          # TODO
        end
      end
    end
  end
end
