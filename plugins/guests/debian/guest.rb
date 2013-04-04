require 'set'
require 'tempfile'

require "vagrant"
require 'vagrant/util/template_renderer'

require Vagrant.source_root.join("plugins/guests/linux/guest")

module VagrantPlugins
  module GuestDebian
    class Guest < VagrantPlugins::GuestLinux::Guest
      # Make the TemplateRenderer top-level
      include Vagrant::Util

      def detect?(machine)
        machine.communicate.test("cat /proc/version | grep 'Debian'")
      end

      def change_host_name(name)
        vm.communicate.tap do |comm|
          if !comm.test("hostname --fqdn | grep '^#{name}$' || hostname --short | grep '^#{name}$'")
            comm.sudo("sed -r -i 's/^(127[.]0[.]1[.]1[[:space:]]+).*$/\\1#{name} #{name.split('.')[0]}/' /etc/hosts")
            comm.sudo("sed -i 's/.*$/#{name.split('.')[0]}/' /etc/hostname")
            comm.sudo("hostname -F /etc/hostname")
            comm.sudo("hostname --fqdn > /etc/mailname")
          end
        end
      end
    end
  end
end
