module VagrantPlugins
  module GuestAtomic
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          machine.communicate.sudo("hostnamectl set-hostname #{name}")
        end
      end
    end
  end
end
