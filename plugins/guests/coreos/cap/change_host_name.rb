module VagrantPlugins
  module GuestCoreOS
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          machine.communicate.tap do |comm|
            if !comm.test("sudo hostname --fqdn | grep '#{name}'")
              comm.sudo("hostname #{name.split('.')[0]}")
            end
          end
        end
      end
    end
  end
end
