module VagrantPlugins
  module GuestRedHat
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

          case machine.guest.capability("flavor")
          when :rhel_7
            update_hostname_rhel7
            update_etc_hosts
          else
            update_sysconfig
            update_hostname
            update_etc_hosts
            update_dhcp_hostnames
            restart_networking
          end
        end

        def should_change?
          new_hostname != current_hostname
        end

        def current_hostname
          @current_hostname ||= get_current_hostname
        end

        def get_current_hostname
          hostname = ''
          block = lambda do |type, data|
            if type == :stdout
              hostname += data.chomp
            end
          end

          execute 'hostname -f', error_check: false, &block
          execute 'hostname',&block if hostname.empty?
          /localhost(\..*)?/.match(hostname) ? '' : hostname
        end

        def update_sysconfig
          sudo "sed -i 's/\\(HOSTNAME=\\).*/\\1#{fqdn}/' /etc/sysconfig/network"
        end

        def update_hostname
          sudo "hostname #{fqdn}"
        end

        def update_hostname_rhel7
          sudo "hostnamectl set-hostname #{fqdn}"
        end

        # /etc/hosts should resemble:
        # 127.0.0.1   host.fqdn.com host localhost ...
        def update_etc_hosts
          s = '[[:space:]]'
          current_fqdn  = Regexp.escape(current_hostname)
          current_short = Regexp.escape(current_hostname.split('.').first.to_s)
          currents      = "\\(#{current_fqdn}#{s}\\+\\|#{current_short}#{s}\\+\\)*" unless current_hostname.empty?
          local_ip      = '127[.]0[.]0[.]1'
          search        = "^\\(#{local_ip}#{s}\\+\\)#{currents}"
          replace       = "\\1#{fqdn} "
          replace       = "#{replace}#{short_hostname} " unless fqdn == short_hostname
          expression    = ['s', search, replace,''].join('@')

          sudo "sed -i '#{expression}' /etc/hosts"
        end

        def update_dhcp_hostnames
          sudo "sed -i 's/\\(DHCP_HOSTNAME=\\).*/\\1\"#{short_hostname}\"/' /etc/sysconfig/network-scripts/ifcfg-*"
        end

        def restart_networking
          sudo 'service network restart'
        end

        def fqdn
          new_hostname
        end

        def short_hostname
          new_hostname.split('.').first
        end

        def execute(cmd, opts=nil, &block)
          machine.communicate.execute(cmd, opts, &block)
        end

        def sudo(cmd, opts=nil, &block)
          machine.communicate.sudo(cmd, opts, &block)
        end
      end
    end
  end
end
