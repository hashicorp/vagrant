module VagrantPlugins
  module GuestSlackware
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          machine.communicate.tap do |comm|
            # Only do this if the hostname is not already set
            if !comm.test("sudo hostname | grep '#{name}'")
              comm.sudo("chmod o+w /etc/hostname")
              comm.sudo("echo #{name} > /etc/hostname")
              comm.sudo("chmod o-w /etc/hostname")
              comm.sudo("hostname -F /etc/hostname")
            end
          end
        end
      end
    end
  end
end
