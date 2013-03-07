module Vagrant
  module Guest
    class Suse < Redhat
      def network_scripts_dir
        '/etc/sysconfig/network/'
      end
      def change_host_name(name)
        # Only do this if the hostname is not already set
        if !vm.channel.test("sudo hostname | grep '#{name}'")
          vm.channel.sudo("echo #{name} > /etc/HOSTNAME")
          vm.channel.sudo("hostname #{name}")
          vm.channel.sudo("sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} #{name.split('.')[0]} @' /etc/hosts")
        end
      end
    end
  end
end
