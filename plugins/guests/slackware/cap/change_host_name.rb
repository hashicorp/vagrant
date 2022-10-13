require_relative '../../linux/cap/change_host_name'

module VagrantPlugins
  module GuestSlackware
    module Cap
      class ChangeHostName
        extend VagrantPlugins::GuestLinux::Cap::ChangeHostName

        def self.change_name_command(name)
          return <<-EOH.gsub(/^ {14}/, "")
          # Set the hostname
          chmod o+w /etc/hostname
          echo '#{name}' > /etc/hostname
          chmod o-w /etc/hostname
          hostname -F /etc/hostname
          EOH
        end
      end
    end
  end
end
