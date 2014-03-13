module VagrantPlugins
  module GuestLinux
    module Cap
      class RSync
        def self.rsync_installed(machine)
          machine.communicate.test("which rsync")
        end

        def self.rsync_pre(machine, opts)
          username = machine.ssh_info[:username]

          machine.communicate.tap do |comm|
            comm.sudo("mkdir -p '#{opts[:guestpath]}'")
            comm.sudo("find '#{opts[:guestpath]}' ! -user vagrant -print0 | " +
              "xargs -0 -r chown -v #{username}:")
          end
        end

        def self.rsync_post(machine, opts)
          machine.communicate.tap do |comm|
            comm.sudo("find '#{opts[:guestpath]}' ! -user vagrant -print0 | " +
              "xargs -0 -r chown -v #{opts[:owner]}:#{opts[:group]}")
          end
        end
      end
    end
  end
end
