module VagrantPlugins
  module GuestFreeBSD
    module Cap
      class RSync
        def self.rsync_install(machine)
          machine.communicate.tap do |comm|
            comm.sudo("pkg_add -r rsync")
          end
        end

        def self.rsync_installed(machine)
          machine.communicate.test("which rsync")
        end

        def self.rsync_command(machine)
          "sudo rsync"
        end

        def self.rsync_post(machine, opts)
          machine.communicate.sudo(
            "find '#{opts[:guestpath]}' '(' ! -user #{opts[:owner]} -or ! -group #{opts[:group]} ')' -print0 | " +
            "xargs -0 -r chown -v #{opts[:owner]}:#{opts[:group]}")
        end
      end
    end
  end
end
