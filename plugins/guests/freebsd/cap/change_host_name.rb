module VagrantPlugins
  module GuestFreeBSD
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          unless machine.communicate.test("hostname -f | grep '^#{name}$' || hostname -s | grep '^#{name}$'", shell: 'sh')
            machine.communicate.sudo("sed -i '' 's/^hostname=.*$/hostname=#{name}/' /etc/rc.conf", shell: 'sh')
            machine.communicate.sudo("hostname #{name}", shell: 'sh')
          end
        end
      end
    end
  end
end
