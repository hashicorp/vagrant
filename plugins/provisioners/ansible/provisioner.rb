require 'tempfile'

require "vagrant/util/template_renderer"

module VagrantPlugins
  module Ansible
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def provision
        ssh = @machine.ssh_info

        options = %W[--private-key=#{ssh[:private_key_path]} --user=#{ssh[:username]}]
        options << "--extra-vars=" + config.extra_vars.map{|k,v| "#{k}=#{v}"}.join(' ') if config.extra_vars
        options << "--inventory-file=#{get_inventory_file}"
        options << "--ask-sudo-pass" if config.ask_sudo_pass

        if config.limit
          if not config.limit.kind_of?(Array)
            config.limit = [config.limit]
          end
          config.limit = config.limit.join(",")
          options << "--limit=#{config.limit}"
        end

        options << "--sudo" if config.sudo
        options << "--sudo-user=#{config.sudo_user}" if config.sudo_user
        options << "--verbose" if config.verbose

        # Assemble the full ansible-playbook command
        command = (%w(ansible-playbook) << options << config.playbook).flatten

        # Write stdout and stderr data, since it's the regular Ansible output
        command << {
          :env => { "ANSIBLE_FORCE_COLOR" => "true" },
          :notify => [:stdout, :stderr]
        }

        begin
          Vagrant::Util::Subprocess.execute(*command) do |type, data|
            if type == :stdout || type == :stderr
              @machine.env.ui.info(data.chomp, :prefix => false)
            end
          end
        rescue Vagrant::Util::Subprocess::LaunchError
          raise Vagrant::Errors::AnsiblePlaybookAppNotFound
        end
      end

      protected

      def get_inventory_file
        if not config.inventory_file
          self.generate_inventory_file
        else
          config.inventory_file
        end
      end

      def generate_inventory_file
        ssh = @machine.ssh_info
        config_file = Vagrant::Util::TemplateRenderer.render("provisioners/ansible/inventory", {
          :host_name  => @machine.name,
          :ssh_host   => ssh[:host],
          :ssh_port   => ssh[:port]
        })

        # Create a temporary ansible inventory file
        temp = Tempfile.new("vagrant_inventory")
        temp.write(config_file)
        temp.close
        temp.path
      end
    end
  end
end
