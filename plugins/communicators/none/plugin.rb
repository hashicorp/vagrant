# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "vagrant"

module VagrantPlugins
  Vagrant::Util::Experimental.guard_with(:none_communicator) do
    module CommunicatorNone
      class Plugin < Vagrant.plugin("2")
        name "none communicator"
        description <<-DESC
        This plugin provides no communication to remote machines.
        It allows Vagrant to manage remote machines without the
        ability to connect to them for configuration/provisioning.
        Any calls to methods provided by this communicator will
        always be successful.
        DESC

        communicator("none") do
          require File.expand_path("../communicator", __FILE__)
          Communicator
        end
      end
    end
  end
end
