module VagrantPlugins
  module GuestArch
    module Cap
      class NFSClient
        def self.nfs_client_install(machine)
          comm = machine.communicate
          comm.sudo <<-EOH.gsub(/^ {12}/, '')
            pacman -Sy --noconfirm
            pacman -S --noconfirm nfs-client
          EOH
        end
      end
    end
  end
end

