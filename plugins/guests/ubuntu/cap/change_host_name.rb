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
          if hardy?
            # hostname.sh returns 1, so use `true` to get a 0 exitcode
            sudo("/etc/init.d/hostname.sh start; true")
          elsif vivid?
            # Service runs via hostnamectl
          else
            sudo("service hostname start")
          end
        end

        def hardy?
          os_version("hardy")
        end

        def vivid?
          os_version("vivid")
        end

        def renew_dhcp
          sudo("ifdown -a; ifup -a; ifup -a --allow=hotplug")
        end

      private

        def os_version(name)
          machine.communicate.test("[ `lsb_release -c -s` = #{name} ]")
        end
      end
    end
  end
end
