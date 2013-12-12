require_relative "docker_client"
require_relative "docker_installer"

module VagrantPlugins
  module Docker
    class DockerError < Vagrant::Errors::VagrantError
      error_namespace("vagrant.provisioners.docker")
    end

    # TODO: Improve handling of vagrant-lxc specifics (like checking for apparmor
    #       profile stuff + autocorrection)
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def initialize(machine, config, installer = nil, client = nil)
        super(machine, config)

        # TODO: Rename to installer / client (drop docker suffix)
        @installer = installer || DockerInstaller.new(@machine, config.version)
        @client    = client    || DockerClient.new(@machine)
      end

      def provision
        @logger = Log4r::Logger.new("vagrant::provisioners::docker")

        @logger.info("Checking for Docker installation...")
        @installer.ensure_installed

        # Attempt to start service if not running
        @client.start_service
        raise DockerError, :not_running if !@client.daemon_running?

        if config.images.any?
          @machine.ui.info(I18n.t("vagrant.docker_pulling_images"))
          @client.pull_images(*config.images)
        end

        if config.build_images.any?
          @machine.ui.info(I18n.t("vagrant.docker_building_images"))
          @client.build_images(config.build_images)
        end

        if config.containers.any?
          @machine.ui.info(I18n.t("vagrant.docker_starting_containers"))
          @client.run(config.containers)
        end
      end
    end
  end
end
