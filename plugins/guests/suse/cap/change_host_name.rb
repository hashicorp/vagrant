require 'vagrant/util/guest_hosts'
require 'vagrant/util/guest_inspection'

module VagrantPlugins
  module GuestSUSE
    module Cap
      class ChangeHostName

        extend Vagrant::Util::GuestInspection::Linux
        extend Vagrant::Util::GuestHosts::Linux

        def self.change_host_name(machine, name)
          comm = machine.communicate
          basename = name.split(".", 2)[0]

          network_with_hostname = machine.config.vm.networks.map {|_, c| c if c[:hostname] }.compact[0]
          if network_with_hostname
            replace_host(comm, name, network_with_hostname[:ip])
          else
            add_hostname_to_loopback_interface(comm, name)
          end

          if hostnamectl?(comm)
            if !comm.test("test \"$(hostnamectl --static status)\" = \"#{basename}\"", sudo: false)
              cmd = <<-EOH.gsub(/^ {14}/, "")
              hostnamectl set-hostname '#{basename}'
              echo #{name} > /etc/HOSTNAME
              EOH
              comm.sudo(cmd)
            end
          else
            if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
              cmd = <<-EOH.gsub(/^ {14}/, "")
              echo #{name} > /etc/HOSTNAME
              hostname '#{basename}'
              EOH
              comm.sudo(cmd)
            end
          end

        end
      end
    end
  end
end
