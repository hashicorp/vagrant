require 'vagrant/util/guest_hosts'

module VagrantPlugins
  module GuestDarwin
    module Cap
      class ChangeHostName
        extend Vagrant::Util::GuestHosts::BSD

        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            basename = name.split(".", 2)[0]

            # LocalHostName should not contain dots - it is used by Bonjour and
            # visible through file sharing services.
            comm.sudo <<-EOH.gsub(/^ */, '')
              # Set hostname
              scutil --set ComputerName '#{name}' &&
                scutil --set HostName '#{name}' &&
                scutil --set LocalHostName '#{basename}'
              result=$?
              if [ $result -ne 0 ]; then
                exit $result
              fi

              hostname '#{name}'
            EOH
          end
          network_with_hostname = machine.config.vm.networks.map {|_, c| c if c[:hostname] }.compact[0]
          if network_with_hostname
            replace_host(comm, name, network_with_hostname[:ip])
          else
            add_hostname_to_loopback_interface(comm, name)
          end
        end
      end
    end
  end
end
