# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require_relative '../../linux/cap/change_host_name'

module VagrantPlugins
  module GuestArch
    module Cap
      class ChangeHostName
        extend VagrantPlugins::GuestLinux::Cap::ChangeHostName

        def self.change_name_command(name)
          "hostnamectl set-hostname '#{name.split(".", 2).first}'"
        end
      end
    end
  end
end
