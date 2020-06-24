require 'vagrant/util/guest_hosts'

module VagrantPlugins
  module GuestAtomic
    module Cap
      class ChangeHostName
        extend Vagrant::Util::GuestHosts::Linux

        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            basename = name.split(".", 2)[0]
            comm.sudo <<-EOH.gsub(/^ {14}/, "")
              # Set hostname
              hostnamectl set-hostname '#{basename}'
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
