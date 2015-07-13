module VagrantPlugins
  module GuestPhoton
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          machine.communicate.tap do |comm|
            unless comm.test("sudo hostname --fqdn | grep '#{name}'")
              comm.sudo("hostname #{name.split('.')[0]}")
            end
          end
        end
      end
    end
  end
end
