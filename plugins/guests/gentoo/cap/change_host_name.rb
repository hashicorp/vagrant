require_relative '../../linux/cap/change_host_name'

module VagrantPlugins
  module GuestGentoo
    module Cap
      class ChangeHostName
        extend VagrantPlugins::GuestLinux::Cap::ChangeHostName

        def self.change_name_command(name)
          basename = name.split(".", 2)[0]
          return <<-EOH.gsub(/^ {14}/, '')
            # Use hostnamectl on systemd
            if [[ `systemctl` =~ -\.mount ]]; then
              systemctl set-hostname '#{name}'
            else
              hostname '#{basename}'
              echo "hostname=#{basename}" > /etc/conf.d/hostname
            fi
          EOH
        end
      end
    end
  end
end
