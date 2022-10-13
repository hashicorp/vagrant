require_relative '../../linux/cap/change_host_name'

module VagrantPlugins
  module GuestOmniOS
    module Cap
      class ChangeHostName
        extend VagrantPlugins::GuestLinux::Cap::ChangeHostName

        def self.change_name_command(name)
          basename = name.split(".", 2)[0]
          return <<-EOH.gsub(/^ {14}/, "")
          # Set hostname
          echo '#{name}' > /etc/nodename
          hostname '#{name}'
          EOH
        end
      end
    end
  end
end
