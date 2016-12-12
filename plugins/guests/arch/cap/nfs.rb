module VagrantPlugins
  module GuestArch
    module Cap
      class NFS
        def self.nfs_client_installed(machine)
          machine.communicate.test("pacman -Q nfs-utils")
        end

        def self.nfs_pre(machine)
          comm = machine.communicate

          # There is a bug in NFS where the rpcbind functionality is not started
          # and it's not a dependency of nfs-utils. Read more here:
          #
          #   https://bbs.archlinux.org/viewtopic.php?id=193410
          #
          comm.sudo <<-EOH.gsub(/^ {12}/, "")
            systemctl enable rpcbind &&
            systemctl start rpcbind
          EOH
        end

        def self.nfs_client_install(machine)
          comm = machine.communicate
          comm.sudo <<-EOH.gsub(/^ {12}/, "")
            pacman --noconfirm -Syy &&
            pacman --noconfirm -S nfs-utils ntp
          EOH
        end
      end
    end
  end
end
