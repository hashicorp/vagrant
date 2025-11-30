# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

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
