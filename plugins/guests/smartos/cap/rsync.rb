module VagrantPlugins
  module GuestSmartos
    module Cap
      class RSync
        def self.rsync_installed(machine)
          machine.communicate.test("which rsync")
        end

        def self.rsync_install(machine, folder_opts)
          username = machine.ssh_info[:username]
          sudo = machine.config.smartos.suexec_cmd

          machine.communicate.tap do |comm|
            comm.execute("#{sudo} mkdir -p '#{folder_opts[:guestpath]}'")
            comm.execute("#{sudo} chown -R #{username} '#{folder_opts[:guestpath]}'")
          end
        end

        def self.rsync_pre(machine, folder_opts)
          rsync_install(machine, folder_opts)
        end
      end
    end
  end
end
