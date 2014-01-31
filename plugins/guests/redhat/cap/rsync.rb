module VagrantPlugins
  module GuestRedHat
    module Cap
      class RSync
        def self.rsync_install(machine)
          machine.communicate.tap do |comm|
            comm.sudo("yum -y install rsync")
          end
        end
      end
    end
  end
end
