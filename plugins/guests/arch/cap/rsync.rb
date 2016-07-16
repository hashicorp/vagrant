module VagrantPlugins
  module GuestArch
    module Cap
      class RSync
        def self.rsync_install(machine)
          comm = machine.communicate
          if !comm.test("test -f /usr/bin/rsync")
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              pacman -Sy --noconfirm
              pacman -S --noconfirm rsync
            EOH
          end
        end
      end
    end
  end
end

