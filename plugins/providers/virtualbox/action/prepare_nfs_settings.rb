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

          using_nfs = false
          env[:machine].config.vm.synced_folders.each do |id, opts|
            if opts[:nfs]
              using_nfs = true
              break
            end
          end

          if using_nfs
            @logger.info("Using NFS, preparing NFS settings by reading host IP and machine IP")
            env[:nfs_host_ip]    = read_host_ip(env[:machine])
            env[:nfs_machine_ip] = read_machine_ip(env[:machine])

            raise Vagrant::Errors::NFSNoHostonlyNetwork if !env[:nfs_machine_ip]
          end
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
          ips = []
          machine.config.vm.networks.each do |type, options|
            if type == :private_network && options[:ip].is_a?(String)
              ips << options[:ip]
            end
          end

          if ips.empty?
            return nil
          end

          ips
        end
      end
    end
  end
end
