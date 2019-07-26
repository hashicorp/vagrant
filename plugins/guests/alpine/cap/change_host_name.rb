module VagrantPlugins
  module GuestAlpine
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          new(machine, name).change!
        end

        attr_reader :machine, :new_hostname

        def initialize(machine, new_hostname)
          @machine = machine
          @new_hostname = new_hostname
        end

        def change!
          return unless should_change?

          update_etc_hostname
          update_etc_hosts
          refresh_hostname_service
          update_mailname
          renew_dhcp
        end

        def should_change?
          new_hostname != current_hostname
        end

        def current_hostname
          @current_hostname ||= fetch_current_hostname
        end

        def fetch_current_hostname
          hostname = ''
          machine.communicate.sudo 'hostname -f' do |type, data|
            hostname = data.chomp if type == :stdout && hostname.empty?
          end

          hostname
        end

        def update_etc_hostname
          machine.communicate.sudo("echo '#{short_hostname}' > /etc/hostname")
        end

        # /etc/hosts should resemble:
        # 127.0.0.1   localhost
        # 127.0.1.1   host.fqdn.com host.fqdn host
        def update_etc_hosts
          if machine.communicate.test("grep '#{current_hostname}' /etc/hosts")
            # Current hostname entry is in /etc/hosts
            ip_address = '([0-9]{1,3}\.){3}[0-9]{1,3}'
            search     = "^(#{ip_address})\\s+#{Regexp.escape(current_hostname)}(\\s.*)?$"
            replace    = "\\1 #{new_hostname} #{short_hostname}"
            expression = ['s', search, replace, 'g'].join('@')

            machine.communicate.sudo("sed -ri '#{expression}' /etc/hosts")
          else
            # Current hostname entry isn't in /etc/hosts, just append it
            machine.communicate.sudo("echo '127.0.1.1 #{new_hostname} #{short_hostname}' >>/etc/hosts")
          end
        end

        def refresh_hostname_service
          machine.communicate.sudo('hostname -F /etc/hostname')
        end

        def update_mailname
          machine.communicate.sudo('hostname -f > /etc/mailname')
        end

        def renew_dhcp
          machine.communicate.sudo('ifdown -a; ifup -a; ifup eth0')
        end

        def short_hostname
          new_hostname.split('.').first
        end
      end
    end
  end
end
