module VagrantPlugins
  module GuestDarwin
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            basename = name.split(".", 2)[0]

            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              scutil --set ComputerName '#{name}'
              scutil --set HostName '#{name}'

              # LocalHostName should not contain dots - it is used by Bonjour and
              # visible through file sharing services.
              scutil --set LocalHostName '#{basename}'

              hostname '#{name}'

              # Remove comments and blank lines from /etc/hosts
              sed -i'' -e 's/#.*$//' /etc/hosts
              sed -i'' -e '/^$/d' /etc/hosts

              # Prepend ourselves to /etc/hosts - sed on bsd is sad
              grep -w '#{name}' /etc/hosts || {
                echo -e '127.0.0.1\\t#{name}\\t#{basename}' | cat - /etc/hosts > /tmp/tmp-hosts
                mv /tmp/tmp-hosts /etc/hosts
              }
            EOH
          end
        end
      end
    end
  end
end
