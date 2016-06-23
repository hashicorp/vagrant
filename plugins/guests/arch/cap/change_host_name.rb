module VagrantPlugins
  module GuestArch
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'")
            basename = name.split(".", 2)[0]
            comm.sudo <<-EOH.gsub(/^ {14}/, "")
              hostnamectl set-hostname '#{basename}'

              # Remove comments and blank lines from /etc/hosts
              sed -i'' -e 's/#.*$//' -e '/^$/d' /etc/hosts

              # Prepend ourselves to /etc/hosts
              grep -w '#{name}' /etc/hosts || {
                sed -i'' '1i 127.0.0.1\\t#{name}\\t#{basename}' /etc/hosts
              }
            EOH
          end
        end
      end
    end
  end
end
