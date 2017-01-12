module VagrantPlugins
  module GuestDebian
    module Cap
      class RSync
        def self.rsync_install(machine)
          comm = machine.communicate
          comm.sudo <<-EOH.gsub(/^ {14}/, '')
            apt-get -yqq update
            apt-get -yqq install rsync
          EOH
        end
      end
    end
  end
end
