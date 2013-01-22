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
        vm.channel.sudo("shutdown -p now")
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
          vm.channel.sudo("mkdir -p #{opts[:guestpath]}")
          vm.channel.sudo("mount #{ip}:#{opts[:hostpath]} #{opts[:guestpath]}")
        end
      end

      def configure_networks(networks)
        # Remove any previous network additions to the configuration file.
        vm.channel.sudo("sed -i '' -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/rc.conf")

        networks.each do |network|
          entry = TemplateRenderer.render("guests/freebsd/network_#{network[:type]}",
                                          :options => network)

          # Write the entry to a temporary location
          temp = Tempfile.new("vagrant")
          temp.binmode
          temp.write(entry)
          temp.close

          vm.channel.upload(temp.path, "/tmp/vagrant-network-entry")
          vm.channel.sudo("su -m root -c 'cat /tmp/vagrant-network-entry >> /etc/rc.conf'")
          vm.channel.sudo("rm /tmp/vagrant-network-entry")

          if network[:type].to_sym == :static
            vm.channel.sudo("ifconfig em#{network[:interface]} inet #{network[:ip]} netmask #{network[:netmask]}")
          elsif network[:type].to_sym == :dhcp
            vm.channel.sudo("dhclient em#{network[:interface]}")
          end
        end
      end

     def change_host_name(name)
       if !vm.channel.test("hostname -f | grep '^#{name}$' || hostname -s | grep '^#{name}$'")
         vm.channel.sudo("sed -i '' 's/^hostname=.*$/hostname=#{name}/' /etc/rc.conf")
         vm.channel.sudo("hostname #{name}")
       end
     end
    end
  end
end
