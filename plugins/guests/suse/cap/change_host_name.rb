module VagrantPlugins
  module GuestSUSE
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          basename = name.split(".", 2)[0]
          if !comm.test('test "$(hostnamectl --static status)" = "#{basename}"', sudo: false)
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              hostnamectl set-hostname '#{basename}'

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
