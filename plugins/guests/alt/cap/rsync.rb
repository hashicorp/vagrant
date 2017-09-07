module VagrantPlugins
  module GuestALT
    module Cap
      class RSync
        def self.rsync_install(machine)
          machine.communicate.sudo <<-EOH.gsub(/^ {12}/, '')
            apt-get install -y -qq install rsync
          EOH
        end
      end
    end
  end
end
