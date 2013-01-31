require 'vagrant/util/template_renderer'

module VagrantPlugins
  module GuestFreeBSD
    # A general Vagrant system implementation for "freebsd".
    #
    # Contributed by Kenneth Vestergaard <kvs@binarysolutions.dk>
    class Guest < Vagrant.plugin("2", :guest)
      # Here for whenever it may be used.
      class FreeBSDError < Vagrant::Errors::VagrantError
        error_namespace("vagrant.guest.freebsd")
      end

      def halt
        vm.communicate.sudo("shutdown -p now")
      end

      # TODO: vboxsf is currently unsupported in FreeBSD, if you are able to
      # help out with this project, please contact vbox@FreeBSD.org
      #
      # See: http://wiki.freebsd.org/VirtualBox/ToDo
      # def mount_shared_folder(ssh, name, guestpath)
      #   ssh.exec!("sudo mkdir -p #{guestpath}")
      #   # Using a custom mount method here; could use improvement.
      #   ssh.exec!("sudo mount -t vboxfs v-root #{guestpath}")
      #   ssh.exec!("sudo chown #{vm.config.ssh.username} #{guestpath}")
      # end

      def mount_nfs(ip, folders)
        folders.each do |name, opts|
          vm.communicate.sudo("mkdir -p #{opts[:guestpath]}")
          vm.communicate.sudo("mount '#{ip}:#{opts[:hostpath]}' '#{opts[:guestpath]}'")
        end
      end

      def configure_networks(networks)
        # Remove any previous network additions to the configuration file.
        vm.communicate.sudo("sed -i '' -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/rc.conf")

        networks.each do |network|
          entry = TemplateRenderer.render("guests/freebsd/network_#{network[:type]}",
                                          :options => network)

          # Write the entry to a temporary location
          temp = Tempfile.new("vagrant")
          temp.binmode
          temp.write(entry)
          temp.close

          vm.communicate.upload(temp.path, "/tmp/vagrant-network-entry")
          vm.communicate.sudo("su -m root -c 'cat /tmp/vagrant-network-entry >> /etc/rc.conf'")
          vm.communicate.sudo("rm /tmp/vagrant-network-entry")

          if network[:type].to_sym == :static
            vm.communicate.sudo("ifconfig em#{network[:interface]} inet #{network[:ip]} netmask #{network[:netmask]}")
          elsif network[:type].to_sym == :dhcp
            vm.communicate.sudo("dhclient em#{network[:interface]}")
          end
        end
      end

     def change_host_name(name)
       if !vm.communicate.test("hostname -f | grep '^#{name}$' || hostname -s | grep '^#{name}$'")
         vm.communicate.sudo("sed -i '' 's/^hostname=.*$/hostname=#{name}/' /etc/rc.conf")
         vm.communicate.sudo("hostname #{name}")
       end
     end
    end
  end
end
