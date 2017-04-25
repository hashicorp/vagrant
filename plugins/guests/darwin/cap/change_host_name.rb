module VagrantPlugins
  module GuestDarwin
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            basename = name.split(".", 2)[0]

            # LocalHostName should not contain dots - it is used by Bonjour and
            # visible through file sharing services.
            comm.sudo <<-EOH.gsub(/^ */, '')
              # Set hostname
              scutil --set ComputerName '#{name}' &&
                scutil --set HostName '#{name}' &&
                scutil --set LocalHostName '#{basename}'
              result=$?
              if [ $result -ne 0 ]; then
                exit $result
              fi

              hostname '#{name}'

              # Prepend ourselves to /etc/hosts - sed on bsd is sad
              grep -w '#{name}' /etc/hosts || {
                echo -e '127.0.0.1\\t#{name}\\t#{basename}' | cat - /etc/hosts > /tmp/tmp-hosts &&
                  mv /tmp/tmp-hosts /etc/hosts
              }
            EOH
          end
        end
      end
    end
  end
end
