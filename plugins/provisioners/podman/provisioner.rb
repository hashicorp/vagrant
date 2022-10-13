require_relative "../container/provisioner"

require_relative "installer"
require_relative "client"

module VagrantPlugins
  module PodmanProvisioner
    class PodmanError < Vagrant::Errors::VagrantError
      error_namespace("vagrant.provisioners.podman")
    end

    class Provisioner < VagrantPlugins::ContainerProvisioner::Provisioner
      def initialize(machine, config, installer = nil, client = nil)
        super(machine, config, installer, client)

        @installer = installer || Installer.new(@machine)
        @client    = client    || Client.new(@machine)
        @logger = Log4r::Logger.new("vagrant::provisioners::podman")
      end

      def provision
        @logger.info("Checking for Podman installation...")

        if @installer.ensure_installed(config.kubic)
          if !config.post_install_provisioner.nil?
            @logger.info("Running post setup provision script...")
            env = {
                  callable: method(:run_provisioner),
                  provisioner: config.post_install_provisioner,
                  machine: machine}
            machine.env.hook(:run_provisioner, env)
          end
        end

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
