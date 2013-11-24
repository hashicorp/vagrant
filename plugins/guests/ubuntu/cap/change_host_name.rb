module VagrantPlugins
  module GuestUbuntu
    module Cap
      class ChangeHostName < VagrantPlugins::GuestDebian::Cap::ChangeHostName
        def self.change_host_name(machine, name)
          super
        end

        def refresh_hostname_service
          if hardy?
            # hostname.sh returns 1, so use `true` to get a 0 exitcode
            sudo("/etc/init.d/hostname.sh start; true")
          else
            sudo("service hostname start")
          end
        end

        def hardy?
          machine.communicate.test("[ `lsb_release -c -s` = hardy ]")
        end

        def renew_dhcp
          sudo("ifdown -a; ifup -a; ifup -a --allow=hotplug")
        end
      end
    end
  end
end
