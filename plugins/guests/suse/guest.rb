require "vagrant"

require Vagrant.source_root.join("plugins/guests/redhat/guest")

module VagrantPlugins
  module GuestSuse
    class Guest < VagrantPlugins::GuestRedHat::Guest
      def network_scripts_dir
        '/etc/sysconfig/network/'
      end

      def change_host_name(name)
      	vm.communicate.tap do |comm|
  	      # Only do this if the hostname is not already set
  	      if !comm.test("sudo hostname | grep '#{name}'")
  	        comm.sudo("echo '#{name}' > /etc/HOSTNAME")
  	        comm.sudo("hostname #{name}")
  	        comm.sudo("sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} #{name.split('.')[0]} @' /etc/hosts")
  	      end
      	end
      end
    end
  end
end
