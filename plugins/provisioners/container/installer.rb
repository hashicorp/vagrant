module VagrantPlugins
  module ContainerProvisioner
    class Installer
      def initialize(machine)
        @machine = machine
      end

      def ensure_installed
        # nothing to do
      end
    end
  end
end
