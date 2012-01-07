require 'vagrant/guest/debian'

module Vagrant
  module Guest
    class Ubuntu < Debian
      def change_host_name(name)
        if !vm.channel.test("sudo hostname | grep '#{name}'")
          vm.channel.sudo("sed -i 's/.*$/#{name}/' /etc/hostname")
          vm.channel.sudo("sed -i 's@^\\(127[.]0[.]1[.]1[[:space:]]\\+\\)@\\1#{name} #{name.split('.')[0]} @' /etc/hosts")
          vm.channel.sudo("service hostname start")
        end
      end
    end
  end
end
