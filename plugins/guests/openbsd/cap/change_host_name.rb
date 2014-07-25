module VagrantPlugins
  module GuestOpenBSD
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          unless machine.communicate.test("hostname | grep '^#{name}$'")
            machine.communicate.sudo("sh -c \"echo '#{name}' > /etc/myname\"")
            machine.communicate.sudo("hostname #{name}")
          end
        end
      end
    end
  end
end
