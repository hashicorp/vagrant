# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module GuestOpenWrt
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("uci get system.@system[0].hostname | grep '^#{name}$'", sudo: false)
            comm.execute <<~EOH
              uci set system.@system[0].hostname='#{name}'
              uci commit system
              /etc/init.d/system reload
            EOH
          end
        end
      end
    end
  end
end
