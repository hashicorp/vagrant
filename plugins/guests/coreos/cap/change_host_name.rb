require "tempfile"
require "yaml"

module VagrantPlugins
  module GuestCoreOS
    module Cap
      class ChangeHostName
        extend Vagrant::Util::GuestInspection::Linux

        def self.change_host_name(machine, name)
          comm = machine.communicate

          if systemd_unit_file?(comm, "system-cloudinit*")
            file = Tempfile.new("vagrant-coreos-hostname")
            file.puts("#cloud-config\n")
            file.puts({"hostname" => name}.to_yaml)
            file.close

            dst = "/var/tmp/hostname.yml"
            svc_path = dst.tr("/", "-")[1..-1]
            comm.upload(file.path, dst)
            comm.sudo("systemctl start system-cloudinit@#{svc_path}.service")
          else
            if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
              basename = name.split(".", 2)[0]
              comm.sudo("hostname '#{basename}'")

              # Note that when working with CoreOS, we explicitly do not add the
              # entry to /etc/hosts because this file does not exist on CoreOS.
              # We could create it, but the recommended approach on CoreOS is to
              # use Fleet to manage /etc/hosts files.
            end
          end
        end
      end
    end
  end
end
