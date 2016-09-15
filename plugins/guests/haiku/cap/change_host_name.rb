module VagrantPlugins
  module GuestHaiku
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname | grep '^#{name}$'", sudo: false)
            basename = name.split(".", 2)[0]
            comm.execute <<-EOH.gsub(/^ {14}/, '')
              # Ensure exit on command error
              set -e

              SYS_CONFIG_DIR=$(finddir B_SYSTEM_SETTINGS_DIRECTORY)

              # Set the hostname
              echo '#{basename}' > $SYS_CONFIG_DIR/network/hostname
              hostname '#{basename}'

              # Remove comments and blank lines from /etc/hosts
              sed -i'' -e 's/#.*$//' -e '/^$/d' $SYS_CONFIG_DIR/network/hosts

              # Prepend ourselves to /etc/hosts
              grep -w '#{name}' /etc/hosts || {
                sed -i'' '1i 127.0.0.1\\t#{name}\\t#{basename}' $SYS_CONFIG_DIR/network/hosts
              }
            EOH
          end
        end
      end
    end
  end
end
