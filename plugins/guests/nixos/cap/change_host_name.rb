require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestNixos
    module Cap
      class ChangeHostName
        include Vagrant::Util

        def self.change_host_name(machine, name)
          # upload the config file
          hostname_module = TemplateRenderer.render("guests/nixos/hostname", name: name)
          upload(machine, hostname_module, "/etc/nixos/vagrant-hostname.nix")
        end

        # Upload a file.
        def self.upload(machine, content, remote_path)
          remote_temp = mktemp(machine)

          Tempfile.open("vagrant-nixos-change-host-name") do |f|
            f.binmode
            f.write(content)
            f.fsync
            f.close
            machine.communicate.upload(f.path, "#{remote_temp}")
          end

          machine.communicate.sudo("mv #{remote_temp} #{remote_path}")
        end

        # Create a temp file.
        def self.mktemp(machine)
          path = nil

          machine.communicate.execute("mktemp --suffix -vagrant-upload") do |type, result|
            path = result.chomp if type == :stdout
          end
          path
        end
      end
    end
  end
end
