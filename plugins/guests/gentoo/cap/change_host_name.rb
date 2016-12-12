module VagrantPlugins
  module GuestGentoo
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            basename = name.split(".", 2)[0]
            comm.sudo <<-EOH.gsub(/^ {14}/, "")
              # Set the hostname
              hostname '#{basename}'
              echo "hostname=#{basename}" > /etc/conf.d/hostname

              # Remove comments and blank lines from /etc/hosts
              sed -i'' -e 's/#.*$//' /etc/hosts
              sed -i'' -e '/^$/d' /etc/hosts

              # Prepend ourselves to /etc/hosts
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
