module VagrantPlugins
  module GuestLinux
    module Cap
      class RSync
        def self.rsync_installed(machine)
          machine.communicate.test("which rsync")
        end

        def self.rsync_pre(machine, folder_opts)
          username = machine.ssh_info[:username]

          machine.communicate.tap do |comm|
            comm.sudo("mkdir -p '#{folder_opts[:guestpath]}'")
            comm.sudo("chown -R #{username} '#{folder_opts[:guestpath]}'")
          end
        end

        def self.rsync_post(machine, opts)
          machine.communicate.tap do |comm|
            comm.sudo("chown -R #{opts[:owner]}:#{opts[:group]} '#{opts[:guestpath]}'")
          end
        end
      end
    end
  end
end
