require_relative '../../linux/cap/change_host_name'

module VagrantPlugins
  module GuestPhoton
    module Cap
      class ChangeHostName
        extend VagrantPlugins::GuestLinux::Cap::ChangeHostName

        def self.change_name_command(name)
          return <<-EOH.gsub(/^ {14}/, "")
             # Set the hostname
            echo '#{name}' > /etc/hostname
            hostname '#{name}'
          EOH
        end
      end
    end
  end
end
