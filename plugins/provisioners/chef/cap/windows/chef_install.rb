# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../omnibus"

module VagrantPlugins
  module Chef
    module Cap
      module Windows
        module ChefInstall
          def self.chef_install(machine, project, version, channel, omnibus_url, options = {})
            command = Omnibus.ps_command(project, version, channel, omnibus_url, options)
            machine.communicate.sudo(command)
          end
        end
      end
    end
  end
end
