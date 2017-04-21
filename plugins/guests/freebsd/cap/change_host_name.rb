module VagrantPlugins
  module GuestFreeBSD
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false, shell: "sh")
            basename = name.split(".", 2)[0]
            command = <<-EOH.gsub(/^ {14}/, '')
              # Set the hostname
              hostname '#{name}'
              sed -i '' 's/^hostname=.*$/hostname=\"#{name}\"/' /etc/rc.conf

              # Prepend ourselves to /etc/hosts
              grep -w '#{name}' /etc/hosts || {
                echo -e '127.0.0.1\\t#{name}\\t#{basename}' | cat - /etc/hosts > /tmp/tmp-hosts
                mv /tmp/tmp-hosts /etc/hosts
              }
            EOH
            comm.sudo(command, shell: "sh")
          end
        end
      end
    end
  end
end
