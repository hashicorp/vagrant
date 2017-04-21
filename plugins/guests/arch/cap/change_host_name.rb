module VagrantPlugins
  module GuestArch
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            basename = name.split(".", 2)[0]
            comm.sudo <<-EOH.gsub(/^ {14}/, "")
              # Set hostname
              hostnamectl set-hostname '#{basename}'

              # Prepend ourselves to /etc/hosts
              test $? -eq 0 && (grep -w '#{name}' /etc/hosts || {
                sed -i'' '1i 127.0.0.1\\t#{name}\\t#{basename}' /etc/hosts
              })
            EOH
          end
        end
      end
    end
  end
end
