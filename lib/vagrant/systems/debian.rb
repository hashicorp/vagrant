module Vagrant
  module Systems
    class Debian < Linux
      def prepare_host_only_network(net_options=nil)
        # Remove any previous host only network additions to the
        # interface file.
        vm.ssh.execute do |ssh|
          # Clear out any previous entries
          ssh.exec!("sudo sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/network/interfaces > /tmp/vagrant-network-interfaces")
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-interfaces > /etc/network/interfaces'")
          ssh.exit
        end
      end

      def enable_host_only_network(net_options)
        entry = TemplateRenderer.render_to_file('network_entry_debian', :net_options => net_options)
        begin
          vm.ssh.upload!(entry.path, "/tmp/vagrant-network-entry")
        rescue ::Vagrant::Errors::VagrantError => e
        end

        entry.unlink
        vm.ssh.execute do |ssh|
          #This ifdown command fails to begin with, so we don't type + error check,
          #rather just type, then let execute do the usual last-error check at the end.
          ssh.vagrant_type(ssh.vagrant_remote_cmd("sudo /sbin/ifdown eth#{net_options[:adapter]} 2> /dev/null"))
          ssh.vagrant_type(ssh.vagrant_remote_cmd("sudo su -c 'cat /tmp/vagrant-network-entry >> /etc/network/interfaces'"))
          ssh.vagrant_type(ssh.vagrant_remote_cmd("sudo /sbin/ifup eth#{net_options[:adapter]}"))
        end
      end

      def change_host_name(name)
        vm.ssh.execute do |ssh|
          if !ssh.test?("sudo hostname | grep '#{name}'")
            ssh.exec!("sudo sed -i 's@^\\(127[.]0[.]1[.]1[[:space:]]\\+\\)@\\1#{name} #{name.split('.')[0]} @' /etc/hosts")
            ssh.exec!("sudo sed -i 's/.*$/#{name}/' /etc/hostname")
            ssh.exec!("sudo hostname -F /etc/hostname")
          end
        end
      end
    end
  end
end
