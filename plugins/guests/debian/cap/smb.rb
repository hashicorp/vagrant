module VagrantPlugins
  module GuestDebian
    module Cap
      class SMB
        def self.smb_install(machine)
          # Deb/Ubuntu require mount.cifs which doesn't come by default.
          machine.communicate.tap do |comm|
            if !comm.test("test -f /sbin/mount.cifs")
              machine.ui.detail(I18n.t("vagrant.guest_deb_installing_smb"))
              comm.sudo("apt-get -y update")
              comm.sudo("apt-get -y install cifs-utils")
            end
          end
        end
      end
    end
  end
end
