require "tempfile"

require "vagrant/util/template_renderer"

module VagrantPlugins
  module GuestCoreOS
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          machine.communicate.tap do |comm|
            # Remove any previous host only network additions to the interface file
            comm.sudo("systemctl stop etcd")

            primary_machine = machine.env.active_machines
            #machine.env[:primary_machine].provider.driver.read_network_interfaces
            #puts machine.env['admin1'].provider_config.network_adapters
            #puts primary_machine

            # Configure each network interface
            interfaces = []
            comm.sudo("ifconfig | grep enp0 | cut -f1 -d:") do |_, result|
              interfaces = result.split("\n")
            end

            networks.each do |network|
              comm.sudo("ifconfig #{interfaces[network[:interface].to_i]} #{network[:ip]} netmask #{network[:netmask]}")
            end
            puts 'TODO start etcd'

            primary_machine_config = machine.env.active_machines.first
            primary_machine = machine.env.machine(*primary_machine_config, true)

            get_ip = ->(machine) do
              _, network_config = machine.config.vm.networks.detect { |type, _| type == :private_network}
              network_config[:ip]
            end

            primary_machine_ip = get_ip.(primary_machine)
            if get_ip.(machine) == primary_machine_ip
              entry = TemplateRenderer.render("guests/coreos/etcd.service")
            else
              entry = TemplateRenderer.render("guests/coreos/etcd.service",
                                              :options => {:connect_to => primary_machine_ip})
            end

            puts entry

            Tempfile.open("vagrant", '.') do |temp|
              temp.binmode
              temp.write(entry)
              temp.close
              comm.upload(temp.path, "/tmp/etcd-cluster.service")
            end

            comm.sudo("mv /tmp/etcd-cluster.service /media/state/units/")
            comm.sudo("systemctl restart local-enable.service")
          end

        end
      end
    end
  end
end
