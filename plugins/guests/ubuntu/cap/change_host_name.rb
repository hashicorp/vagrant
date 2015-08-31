module VagrantPlugins
  module GuestUbuntu
    module Cap
      class ChangeHostName < VagrantPlugins::GuestDebian::Cap::ChangeHostName
        def self.change_host_name(machine, name)
          super
        end

        def update_etc_hostname
          return super unless systemd?
          sudo("hostnamectl set-hostname '#{short_hostname}'")
        end

        def refresh_hostname_service
          if hardy?
            # hostname.sh returns 1, so use `true` to get a 0 exitcode
            sudo("/etc/init.d/hostname.sh start; true")
          elsif systemd?
            # Service runs via hostnamectl
          else
            sudo("service hostname start")
          end
        end

        def hardy?
          os_version("hardy")
        end

        def renew_dhcp
          sudo("ifdown -a; ifup -a; ifup -a --allow=hotplug")
        end

      private

        def init_package
          machine.communicate.execute('cat /proc/1/comm') do |type, data|
            return data.chomp if type == :stdout
          end
        end

        def os_version(name)
          machine.communicate.test("[ `lsb_release -c -s` = #{name} ]")
        end

        def systemd?
          init_package == 'systemd'
        end
      end
    end
  end
end
