module VagrantPlugins
  module GuestFreeBSD
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          options = { shell: "sh" }
          comm = machine.communicate

          if !comm.test("hostname -f | grep -w '#{name}' || hostname -s | grep -w '#{name}'", options)
            basename = name.split(".", 2)[0]
            command = <<-EOH.gsub(/^ {14}/, '')
              set -e

              # Set the hostname
              hostname '#{name}'
              sed -i '' 's/^hostname=.*$/hostname=\"#{name}\"/' /etc/rc.conf

              # Remove comments and blank lines from /etc/hosts
              sed -i'' -e 's/#.*$//' /etc/hosts
              sed -i'' -e '/^$/d' /etc/hosts

              # Prepend ourselves to /etc/hosts
              grep -w '#{name}' /etc/hosts || {
                echo -e '127.0.0.1\\t#{name}\\t#{basename}' | cat - /etc/hosts > /tmp/tmp-hosts
                mv /tmp/tmp-hosts /etc/hosts
              }
            EOH
            comm.sudo(command, options)
          end
        end
      end
    end
  end
end
