module VagrantPlugins
  module GuestOPNsense
    module Cap
      class ChangeHostName
        extend Vagrant::Util::GuestHosts::BSD

        def self.change_host_name(machine, name)
          comm = machine.communicate

          unless comm.test("hostname -f | grep '^#{name}$'", sudo: false, shell: "sh")
            basename = name.split(".", 2)[0]
            domain = name.split(".", 2).drop(1).join('.') || "localdomain"

            # Set the hostname and reload firewall
            # sudo required because only root user has permissions for following tasks
            command = <<-EOH.gsub(/^ {14}/, '')
              sudo sed -i '' 's@\\(<hostname>\\).*\\(</hostname>\\)@\\1#{basename}\\2@g' /conf/config.xml
              sudo sed -i '' 's@\\(<domain>\\).*\\(</domain>\\)@\\1#{domain}\\2@g' /conf/config.xml
              sudo /usr/local/etc/rc.reload_all
            EOH
            comm.sudo(command, shell: "sh")
          end
        end
      end
    end
  end
end
