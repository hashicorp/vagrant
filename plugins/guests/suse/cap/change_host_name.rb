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
            echo #{name} > /etc/HOSTNAME
            EOH
            network_with_hostname = machine.config.vm.networks.map {|t, c| c if c[:hostname] }.compact[0]
            if network_with_hostname
              replace_host(comm, name, basename, network_with_hostname[:ip])
            else
              add_hostname_to_loopback(comm, name, basename)
            end
          end
        end

        def self.add_hostname_to_loopback(comm, name, basename)
          # Add hostname to /etc/hosts if not already there
          comm.sudo <<-EOH.gsub(/^ {14}/, '')
          grep -w '#{name}' /etc/hosts || {
            sed -i'' '1i 127.0.0.1\\t#{name}\\t#{basename}' /etc/hosts
          }
          EOH
        end

        def self.replace_host(comm, name, basename, ip)
          # Remove any line in /etc/hosts that contains hostname,
          # then add hostname with associated ip 
          comm.sudo <<-EOH.gsub(/^ {14}/, '')
          sed -i '/#{name}/d' /etc/hosts
          sed -i'' '1i '#{ip}'\\t#{name}\\t#{basename}' /etc/hosts
          EOH
        end
      end
    end
  end
end
