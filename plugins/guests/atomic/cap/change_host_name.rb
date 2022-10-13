require_relative '../../linux/cap/change_host_name'

module VagrantPlugins
  module GuestAtomic
    module Cap
      class ChangeHostName
        extend VagrantPlugins::GuestLinux::Cap::ChangeHostName

        def self.change_name_command(name)
          "hostnamectl set-hostname '#{name.split(".", 2).first}'"
        end
      end
    end
  end
end
