require 'vagrant/guest/debian'

module Vagrant
  module Guest
    class Ubuntu < Debian
      def change_host_name(name)
        vm.ssh.execute do |ssh|
          if !ssh.test?("sudo hostname | grep '#{name}'")
            ssh.exec!("sudo sed -i 's/.*$/#{name}/' /etc/hostname")
            ssh.exec!("sudo sed -i 's@^\\(127[.]0[.]1[.]1[[:space:]]\\+\\)@\\1#{name} #{name.split('.')[0]} @' /etc/hosts")
            ssh.exec!("sudo service hostname start")
          end
        end
      end
    end
  end
end
