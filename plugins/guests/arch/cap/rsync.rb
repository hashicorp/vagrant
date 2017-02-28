module VagrantPlugins
  module GuestArch
    module Cap
      class RSync
        def self.rsync_install(machine)
          comm = machine.communicate
          comm.sudo <<-EOH.gsub(/^ {12}/, '')
            pacman -Sy --noconfirm
            pacman -S --noconfirm rsync
            exit $?
          EOH
        end
      end
    end
  end
end
