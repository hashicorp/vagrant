module VagrantPlugins
  module GuestSUSE
    module Cap
      class RSync
        def self.rsync_installed(machine)
          machine.communicate.test("test -f /usr/bin/rsync")
        end

        def self.rsync_install(machine)
          machine.communicate.tap do |comm|
            comm.sudo("zypper -n install rsync")
          end
        end
      end
    end
  end
end
