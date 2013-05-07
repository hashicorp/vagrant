module VagrantPlugins
  module GuestGentoo
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          machine.communicate.tap do |comm|
            if !comm.test("sudo hostname --fqdn | grep '#{name}'")
              comm.sudo("echo 'hostname=#{name.split('.')[0]}' > /etc/conf.d/hostname")
              comm.sudo("sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} #{name.split('.')[0]} @' /etc/hosts")
              comm.sudo("hostname #{name.split('.')[0]}")
            end
          end
        end
      end
    end
  end
end
