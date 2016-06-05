module VagrantPlugins
  module GuestDebian
    module Cap
      class SMB
        def self.smb_install(machine)
          comm = machine.communicate
          if !comm.test("test -f /sbin/mount.cifs")
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              apt-get -yqq update
              apt-get -yqq install cifs-utils
            EOH
          end
        end
      end
    end
  end
end
