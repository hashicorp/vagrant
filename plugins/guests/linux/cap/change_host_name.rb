require 'vagrant/util/guest_hosts'

module VagrantPlugins
  module GuestLinux
    module Cap
      module ChangeHostName
        module Methods
          def change_name_command(name)
            return <<-EOH.gsub(/^ {14}/, '')
                # Set the hostname
                echo '#{name}' > /etc/hostname
                hostname '#{name}'
              EOH
          end

          def change_host_name?(comm, name)
            !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
          end

          def change_host_name(machine, name)
            comm = machine.communicate
            
            network_with_hostname = machine.config.vm.networks.map {|_, c| c if c[:hostname] }.compact[0]
            if network_with_hostname
              replace_host(comm, name, network_with_hostname[:ip])
            else
              add_hostname_to_loopback_interface(comm, name)
            end

            if change_host_name?(comm, name)
              comm.sudo(change_name_command(name))
            end
          end
        end

        def self.extended(klass)
          klass.extend(Vagrant::Util::GuestHosts::Linux)
          klass.extend(Methods)
        end

        extend Vagrant::Util::GuestHosts::Linux
        extend Methods
      end
    end
  end
end
