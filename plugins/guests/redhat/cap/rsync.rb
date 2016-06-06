module VagrantPlugins
  module GuestRedHat
    module Cap
      class RSync
        def self.rsync_install(machine)
          machine.communicate.sudo <<-EOH.gsub(/^ {12}/, '')
            if command -v dnf; then
              dnf -y install rsync
            else
              yum -y install rsync
            fi
          EOH
        end
      end
    end
  end
end
