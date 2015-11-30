module VagrantPlugins
  module GuestRedHat
    module Cap
      class RSync
        def self.rsync_install(machine)
          machine.communicate.tap do |comm|
            if VagrantPlugins::GuestRedHat::Plugin.dnf?(machine)
              comm.sudo("dnf -y install rsync")
            else
              comm.sudo("yum -y install rsync")
            end
          end
        end
      end
    end
  end
end
