require 'vagrant/util/guest_hosts'

module VagrantPlugins
  module GuestPhoton
    module Cap
      class ChangeHostName
        extend Vagrant::Util::GuestHosts::Linux
        
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
