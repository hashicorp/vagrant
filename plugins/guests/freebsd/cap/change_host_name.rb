require 'vagrant/util/guest_hosts'

module VagrantPlugins
  module GuestFreeBSD
    module Cap
      class ChangeHostName
        extend Vagrant::Util::GuestHosts::BSD

        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false, shell: "sh")
            basename = name.split(".", 2)[0]
            command = <<-EOH.gsub(/^ {14}/, '')
              # Set the hostname
              hostname '#{name}'
              sed -i '' 's/^hostname=.*$/hostname=\"#{name}\"/' /etc/rc.conf
            EOH
            comm.sudo(command, shell: "sh")
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
