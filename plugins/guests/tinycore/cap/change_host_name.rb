# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module GuestTinyCore
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          if !machine.communicate.test("hostname | grep '^#{name}$'")
            machine.communicate.sudo("/usr/bin/sethostname #{name}")
          end
        end
      end
    end
  end
end
