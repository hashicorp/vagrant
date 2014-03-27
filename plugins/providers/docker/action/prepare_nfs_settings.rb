module VagrantPlugins
  module DockerProvider
    module Action
      class PrepareNFSSettings
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::action::vm::nfs")
        end

        def call(env)
          @machine = env[:machine]

          @app.call(env)

          if using_nfs? && !privileged_container?
            raise Errors::NfsWithoutPrivilegedError
          end

          if using_nfs?
            @logger.info("Using NFS, preparing NFS settings by reading host IP and machine IP")
            add_ips_to_env!(env)
          end
        end

        # We're using NFS if we have any synced folder with NFS configured. If
        # we are not using NFS we don't need to do the extra work to
        # populate these fields in the environment.
        def using_nfs?
          @machine.config.vm.synced_folders.any? { |_, opts| opts[:type] == :nfs }
        end

        def privileged_container?
          @machine.provider.driver.privileged?(@machine.id)
        end

        # Extracts the proper host and guest IPs for NFS mounts and stores them
        # in the environment for the SyncedFolder action to use them in
        # mounting.
        #
        # The ! indicates that this method modifies its argument.
        def add_ips_to_env!(env)
          provider = env[:machine].provider

          host_ip    = provider.driver.docker_bridge_ip
          machine_ip = provider.ssh_info[:host]

          raise Vagrant::Errors::NFSNoHostonlyNetwork if !host_ip || !machine_ip

          env[:nfs_host_ip]    = host_ip
          env[:nfs_machine_ip] = machine_ip
        end
      end
    end
  end
end
