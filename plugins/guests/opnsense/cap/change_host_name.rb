module VagrantPlugins
  module GuestOPNsense
    module Cap
      class ChangeHostName
        extend Vagrant::Util::GuestHosts::BSD

        def self.change_host_name(machine, name)
          comm = machine.communicate

          unless comm.test("hostname -f | grep '^#{name}$'", sudo: false, shell: "sh")
            command = <<-EOH.gsub(/^ {14}/, '')
              # Set the hostname and reload firewall
              sudo sed -i '' 's@\\(<hostname>\\).*\\(</hostname>\\)@\\1#{name}\\2@g' /conf/config.xml
              sudo /usr/local/etc/rc.reload_all
            EOH
            comm.sudo(command, shell: "sh")
          end
        end
      end
    end
  end
end
