module VagrantPlugins
  module GuestDebian
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
          @current_hostname ||= get_current_hostname
        end

        def get_current_hostname
          hostname = ""
          sudo "hostname -f" do |type, data|
            hostname = data.chomp if type == :stdout && hostname.empty?
          end

          hostname
        end

        def update_etc_hostname
          sudo("echo '#{short_hostname}' > /etc/hostname")
        end

        # /etc/hosts should resemble:
        # 127.0.0.1   localhost
        # 127.0.1.1   host.fqdn.com host.fqdn host
        def update_etc_hosts
          if test("grep '#{current_hostname}' /etc/hosts")
            # Current hostname entry is in /etc/hosts
            ip_address = '([0-9]{1,3}\.){3}[0-9]{1,3}'
            search     = "^(#{ip_address})\\s+#{Regexp.escape(current_hostname)}(\\s.*)?$"
            replace    = "\\1 #{fqdn} #{short_hostname}"
            expression = ['s', search, replace, 'g'].join('@')

            sudo("sed -ri '#{expression}' /etc/hosts")
          else
            # Current hostname entry isn't in /etc/hosts, just append it
            sudo("echo '127.0.1.1 #{fqdn} #{short_hostname}' >>/etc/hosts")
          end
        end

        def refresh_hostname_service
          sudo("hostname -F /etc/hostname")
        end

        def update_mailname
          sudo("hostname --fqdn > /etc/mailname")
        end

        def renew_dhcp
          sudo("ifdown -a; ifup -a; ifup eth0")
        end

        def fqdn
          new_hostname
        end

        def short_hostname
          new_hostname.split('.').first
        end

        def sudo(cmd, &block)
          machine.communicate.sudo(cmd, &block)
        end

        def test(cmd)
          machine.communicate.test(cmd)
        end
      end
    end
  end
end
