module VagrantPlugins
  module Ansible
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def provision
        ssh = @machine.ssh_info
        
        options = %W[--private-key=#{ssh[:private_key_path]} --user=#{ssh[:username]}]
        options << "--extra-vars=\"#{config.extra_vars}\"" if config.extra_vars
        options << "--inventory-file=#{config.inventory_file}" if config.inventory_file
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
        
        command = (%w(ansible-playbook) << options << config.playbook).flatten
        
        Vagrant::Util::SafeExec.exec(*command)
      end
    end
  end
end
