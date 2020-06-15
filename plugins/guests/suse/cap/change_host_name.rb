require 'vagrant/util/guest_hosts'

module VagrantPlugins
  module GuestSUSE
    module Cap
      class ChangeHostName
        extend Vagrant::Util::GuestHosts::Linux

        def self.change_host_name(machine, name)
          comm = machine.communicate
          basename = name.split(".", 2)[0]
          if !comm.test('test "$(hostnamectl --static status)" = "#{basename}"', sudo: false)
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
            hostnamectl set-hostname '#{basename}'
            echo #{name} > /etc/HOSTNAME
            EOH
            network_with_hostname = machine.config.vm.networks.map {|t, c| c if c[:hostname] }.compact[0]
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
end
