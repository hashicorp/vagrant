module VagrantPlugins
  module DockerProvider
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :image, :cmd, :ports, :volumes, :privileged

      def initialize
        @image      = nil
        @cmd        = UNSET_VALUE
        @ports      = []
        @privileged = UNSET_VALUE
        @volumes    = []
      end

      def finalize!
        @cmd        = [] if @cmd == UNSET_VALUE
        @privileged = false if @privileged == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        # TODO: Detect if base image has a CMD / ENTRYPOINT set before erroring out
        errors << I18n.t("docker_provider.errors.config.cmd_not_set")   if @cmd == UNSET_VALUE

        { "docker-provider" => errors }
      end

      private

      def using_nfs?(machine)
        machine.config.vm.synced_folders.any? { |_, opts| opts[:type] == :nfs }
      end
    end
  end
end
