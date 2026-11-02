# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module GuestOpenWrt
    module Cap
      class RSync
        def self.rsync_installed(machine)
          machine.communicate.test("which rsync")
        end

        def self.rsync_install(machine)
          machine.communicate.tap do |comm|
            comm.execute <<~EOH
              opkg update
              opkg install rsync
            EOH
          end
        end

        def self.rsync_pre(machine, opts)
          machine.communicate.tap do |comm|
            comm.execute("mkdir -p '#{opts[:guestpath]}'")
          end
        end

        def self.rsync_command(machine)
          "rsync -zz"
        end

        def self.rsync_post(machine, opts)
          # Don't do anything because BusyBox's `find` doesn't support the
          # syntax in plugins/synced_folders/rsync/default_unix_cap.rb.
        end
      end
    end
  end
end
