module VagrantPlugins
  module GuestEnterpriseLinux7

      class Guest < Vagrant.plugin('2', :guest)
        def detect?(machine)
          machine.communicate.test('grep "\(CentOS\|Red Hat Enterprise\) Linux release 7" /etc/redhat-release')
        end
      end

  end
end
