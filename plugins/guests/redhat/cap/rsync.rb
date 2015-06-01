module VagrantPlugins
  module GuestRedHat
    module Cap
      class RSync
        def self.rsync_install(machine)
          machine.communicate.tap do |comm|
            comm.sudo("type rsync yum -y install rsync> /dev/null || yum -y install rsync")
          end
        end
      end
    end
  end
end
