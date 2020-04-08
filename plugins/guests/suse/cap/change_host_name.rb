module VagrantPlugins
  module GuestSUSE
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          basename = name.split(".", 2)[0]
          if comm.test("hostnamectl --static status", sudo: true)
            comm.sudo("hostnamectl set-hostname '#{basename}'")
          else
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              sed -i "s/$(hostname)/#{basename}/g" /etc/hosts
              hostname '#{basename}'
              echo '#{name}' > /etc/HOSTNAME
            EOH
          end
          comm.sudo("sed -i \"s/localhost/localhost #{basename}/g\" /etc/hosts")
        end
      end
    end
  end
end
