# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module GuestOmniOS
    module Cap
      class RSync
        def self.rsync_install(machine)
          machine.communicate.sudo("pkg install rsync")
        end
      end
    end
  end
end
