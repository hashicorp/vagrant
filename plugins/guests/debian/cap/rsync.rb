module VagrantPlugins
  module GuestDebian
    module Cap
      class RSync
        def self.rsync_install(machine)
          machine.communicate.tap do |comm|
            comm.sudo("apt-get -y update")
            comm.sudo("apt-get -y install rsync")
          end
        end
      end
    end
  end
end
