module VagrantPlugins
  module GuestNetBSD
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          unless machine.communicate.test("hostname -s | grep '^#{name}$'")
            machine.communicate.sudo(<<CMDS, shell: 'sh')
set -e
sed -e 's/^hostname=.*$/hostname=#{name}/' /etc/rc.conf > /tmp/rc.conf.vagrant_changehostname_#{name}
mv /tmp/rc.conf.vagrant_changehostname_#{name} /etc/rc.conf
hostname #{name}
CMDS
          end
        end
      end
    end
  end
end
