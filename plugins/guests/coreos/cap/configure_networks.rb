require "tempfile"

require "vagrant/util/template_renderer"

module VagrantPlugins
  module GuestCoreOS
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          machine.communicate.tap do |comm|
            # Disable default etcd
            comm.sudo("systemctl stop etcd")

            # Read network interface names
            interfaces = []
            comm.sudo("ifconfig | grep enp0 | cut -f1 -d:") do |_, result|
              interfaces = result.split("\n")
            end

            # Configure interfaces
            # FIXME: fix matching of interfaces with IP adresses
            networks.each do |network|
              comm.sudo("ifconfig #{interfaces[network[:interface].to_i]} #{network[:ip]} netmask #{network[:netmask]}")
            end

            primary_machine_config = machine.env.active_machines.first
            primary_machine = machine.env.machine(*primary_machine_config, true)

            get_ip = ->(machine) do
              _, network_config = machine.config.vm.networks.detect { |type, _| type == :private_network}
              network_config[:ip]
            end

            primary_machine_ip = get_ip.(primary_machine)
            current_ip = get_ip.(machine)
            if current_ip == primary_machine_ip
              entry = TemplateRenderer.render("guests/coreos/etcd.service", :options => {
                  :my_ip => current_ip
                })
            else
              connection_string = "#{primary_machine_ip}:7001"
              entry = TemplateRenderer.render("guests/coreos/etcd.service", :options => {
                :connection_string => connection_string,
                :my_ip => current_ip
              })
            end

            Tempfile.open("vagrant") do |temp|
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
