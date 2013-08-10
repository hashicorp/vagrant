module VagrantPlugins
  module GuestArch
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          machine.communicate.tap do |comm|
            # Only do this if the hostname is not already set
            if !comm.test("sudo hostname | grep '#{name}'")
              comm.sudo("hostnamectl set-hostname #{name}")
              comm.sudo("sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} @' /etc/hosts")
            end
          end
        end
      end
    end
  end
end
