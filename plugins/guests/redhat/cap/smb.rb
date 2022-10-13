module VagrantPlugins
  module GuestRedHat
    module Cap
      class SMB
        def self.smb_install(machine)
          comm = machine.communicate
          if !comm.test("test -f /sbin/mount.cifs")
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              if command -v dnf; then
                dnf -y install cifs-utils
              else
                yum -y install cifs-utils
              fi
            EOH
          end
        end
      end
    end
  end
end
