require 'vagrant/util/template_renderer'

module VagrantPlugins
  module GuestFreeBSD
    # A general Vagrant system implementation for "freebsd".
    #
    # Contributed by Kenneth Vestergaard <kvs@binarysolutions.dk>
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        # TODO: FreeBSD detection
        false
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
    end
  end
end
