module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class PrepareNFSSettings
        def initialize(app,env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::action::vm::nfs")
        end

        def call(env)
          @app.call(env)

          env[:nfs_host_ip]    = read_host_ip(env[:machine])
          env[:nfs_machine_ip] = read_machine_ip(env[:machine])
        end

        # Returns the IP address of the first host only network adapter
        #
        # @param [Machine] machine
        # @return [String]
        def read_host_ip(machine)
          machine.provider.driver.read_network_interfaces.each do |adapter, opts|
            if opts[:type] == :hostonly
              machine.provider.driver.read_host_only_interfaces.each do |interface|
                if interface[:name] == opts[:hostonly]
                  return interface[:ip]
                end
              end
            end
          end

          nil
        end

        # Returns the IP address of the guest by looking at the first
        # enabled host only network.
        #
        # @return [String]
        def read_machine_ip(machine)
          machine.config.vm.networks.each do |type, options|
            if type == :private_network && options[:ip].is_a?(String)
              return options[:ip]
            end
          end

          nil
        end
      end
    end
  end
end
