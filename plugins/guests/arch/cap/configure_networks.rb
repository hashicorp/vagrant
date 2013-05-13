module VagrantPlugins
  module GuestArch
    module Cap
      class ConfigureNetworks
        def self.configure_networks(machine, networks)
          networks.each do |network|
            entry = TemplateRenderer.render("guests/arch/network_#{network[:type]}",
                                            :options => network)

            temp = Tempfile.new("vagrant")
            temp.binmode
            temp.write(entry)
            temp.close

            machine.communicate.upload(temp.path, "/tmp/vagrant_network")
            machine.communicate.sudo("mv /tmp/vagrant_network /etc/network.d/interfaces/eth#{network[:interface]}")
            machine.communicate.sudo("netcfg interfaces/eth#{network[:interface]}")
          end
        end
      end
    end
  end
end
