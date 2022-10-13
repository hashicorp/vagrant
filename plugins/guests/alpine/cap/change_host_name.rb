require 'vagrant/util/guest_hosts'

module VagrantPlugins
  module GuestAlpine
    module Cap
      class ChangeHostName
        include Vagrant::Util::GuestHosts::Linux

        def self.change_host_name(machine, name)
          new(machine, name).change!
        end

        attr_reader :machine, :new_hostname

        def initialize(machine, new_hostname)
          @machine = machine
          @new_hostname = new_hostname
        end

        def change!
          update_etc_hosts
          return unless should_change?

          update_etc_hostname
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
          comm = machine.communicate
          network_with_hostname = machine.config.vm.networks.map {|_, c| c if c[:hostname] }.compact[0]
          if network_with_hostname
            replace_host(comm, new_hostname, network_with_hostname[:ip])
          else
            add_hostname_to_loopback_interface(comm, new_hostname)
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
