module VagrantPlugins
  module GuestHaiku
    module Cap
      class RSync
        def self.rsync_installed(machine)
          machine.communicate.test("test -f /bin/rsync")
        end

        def self.rsync_install(machine)
          machine.communicate.execute("pkgman install -y rsync")
        end

        def self.rsync_command(machine)
          "rsync -zz"
        end
      end
    end
  end
end
