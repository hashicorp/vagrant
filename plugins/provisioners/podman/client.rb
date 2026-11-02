# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: MIT

require_relative "../container/client"

module VagrantPlugins
  module PodmanProvisioner
    class Client < VagrantPlugins::ContainerProvisioner::Client
      def initialize(machine)
        super(machine, "podman")
        @container_command = "podman"
      end
    end
  end
end
