require 'tempfile'

require "vagrant/util/template_renderer"

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
          local_temp = Tempfile.new("vagrant-upload")
          local_temp.binmode
          local_temp.write(content)
          local_temp.close
          remote_temp = mktemp(machine)
          machine.communicate.upload(local_temp.path, "#{remote_temp}")
          local_temp.delete
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
