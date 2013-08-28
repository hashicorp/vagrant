module VagrantPlugins
  module Ansible
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def provision
        ssh = @machine.ssh_info

        options = %W[--private-key=#{ssh[:private_key_path]} --user=#{ssh[:username]}]
        options << "--inventory-file=#{config.inventory_path}" if config.inventory_path
        options << "--ask-sudo-pass" if config.ask_sudo_pass

        if config.extra_vars
          extra_vars = config.extra_vars.map do |k,v|
            v = v.gsub('"', '\\"')
            if v.include?(' ')
              v = v.gsub("'", "\\'")
              v = "'#{v}'"
            end

            "#{k}=#{v}"
          end

          options << "--extra-vars=\"#{extra_vars.join(" ")}\""
        end

        if config.limit
          if not config.limit.kind_of?(Array)
            config.limit = [config.limit]
          end
          config.limit = config.limit.join(",")
          options << "--limit=#{config.limit}"
        end

        options << "--sudo" if config.sudo
        options << "--sudo-user=#{config.sudo_user}" if config.sudo_user
        if config.verbose
          options << (config.verbose.to_s == "extra" ?  "-vvv" :  "--verbose")
        end

        # Assemble the full ansible-playbook command
        command = (%w(ansible-playbook) << options << config.playbook).flatten

        # Write stdout and stderr data, since it's the regular Ansible output
        command << {
          :env => { "ANSIBLE_FORCE_COLOR" => "true" },
          :notify => [:stdout, :stderr]
        }

        begin
          result = Vagrant::Util::Subprocess.execute(*command) do |type, data|
            if type == :stdout || type == :stderr
              @machine.env.ui.info(data, :new_line => false, :prefix => false)
            end
          end

          raise Vagrant::Errors::AnsibleFailed if result.exit_code != 0
        rescue Vagrant::Util::Subprocess::LaunchError
          raise Vagrant::Errors::AnsiblePlaybookAppNotFound
        end
      end
    end
  end
end
