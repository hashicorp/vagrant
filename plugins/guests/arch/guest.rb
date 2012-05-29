require 'set'
require 'tempfile'

require "vagrant"
require 'vagrant/util/template_renderer'

require Vagrant.source_root.join("plugins/guests/linux/guest")

module VagrantPlugins
  module GuestArch
    class Guest < VagrantPlugins::GuestLinux::Guest
      # Make the TemplateRenderer top-level
      include Vagrant::Util

      def change_host_name(name)
        # Only do this if the hostname is not already set
        if !vm.channel.test("sudo hostname | grep '#{name}'")
          vm.channel.sudo("sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/rc.conf")
          vm.channel.sudo("hostname #{name}")
          vm.channel.sudo("sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} @' /etc/hosts")
        end
      end

      def configure_networks(networks)
        networks.each do |network|
          interfaces.add(network[:interface])

          entry = TemplateRenderer.render("guests/arch/network_#{network[:type]}", :options => network)

          temp = Tempfile.new("vagrant")
          temp.binmode
          temp.write(entry)
          temp.close

          vm.channel.upload(temp.path, temp.path)
          vm.channel.sudo("mv #{temp.path} /etc/network.d/interfaces/eth#{network[:interface]}")
          vm.channel.sudo("netcfg interfaces/eth#{interface}")
        end
      end
    end
  end
end
