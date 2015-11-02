module VagrantPlugins
  module GuestUbuntu
    module Cap
      class ChangeHostName < VagrantPlugins::GuestDebian::Cap::ChangeHostName
        def self.change_host_name(machine, name)
          super
        end

        def update_etc_hostname
          return super unless vivid?
          sudo("hostnamectl set-hostname '#{short_hostname}'")
        end

        def refresh_hostname_service
          os = os_version

          if hardy?
            # hostname.sh returns 1, so use `true` to get a 0 exitcode
            sudo("/etc/init.d/hostname.sh start; true")
          elsif !os.nil? and os >= 15.0
            # Service runs via hostnamectl
          else
            sudo("service hostname start")
          end
        end

        def hardy?
          os_version() == 8.04
        end

        def vivid?
          os_version() == 15.04
        end

        def renew_dhcp
          sudo("ifdown -a; ifup -a; ifup -a --allow=hotplug")
        end

      private

        def os_version
          cmd = "lsb_release -r -s"
          result = nil
          machine.communicate.execute(cmd) do |type, data|
            result = data.strip.to_f if type == :stdout
          end
        end
      end
    end
  end
end
