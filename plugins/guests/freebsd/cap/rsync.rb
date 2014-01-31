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

        def self.rsync_pre(machine, folder_opts)
          username = machine.ssh_info[:username]

          machine.communicate.tap do |comm|
            comm.sudo("mkdir -p '#{folder_opts[:guestpath]}'", shell: "sh")
            comm.sudo("chown -R #{username} '#{folder_opts[:guestpath]}'", shell: "sh")
          end
        end
      end
    end
  end
end
