module Vagrant
  module Systems
    class Arch < Linux
      def change_host_name(name)
        vm.ssh.execute do |ssh|
          # Only do this if the hostname is not already set
          if !ssh.test?("sudo hostname | grep '#{name}'")
            ssh.exec!("sudo sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/rc.conf")
            ssh.exec!("sudo hostname #{name}")
            ssh.exec!("sudo sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} @' /etc/hosts")
          end
        end
      end
    end
  end
end
