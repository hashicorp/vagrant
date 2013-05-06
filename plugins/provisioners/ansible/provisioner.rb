module VagrantPlugins
  module Ansible
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def provision
        ssh = @machine.ssh_info

        # Connect with Vagrant user (unless --user or --private-key are overidden by 'raw_arguments')
        options = %W[--private-key=#{ssh[:private_key_path]} --user=#{ssh[:username]}]

        # Joker! Not (yet) supported arguments can be passed this way.
        options << "#{config.raw_arguments}" if config.raw_arguments

        # Append Provisioner options (higher precedence):
        options << "--extra-vars=" + config.extra_vars.map{|k,v| "#{k}=#{v}"}.join(' ') if config.extra_vars
        options << "--inventory-file=#{config.inventory_file}" if config.inventory_file
        options << "--ask-sudo-pass" if config.ask_sudo_pass
        options << "--tags=#{as_list_argument(config.tags)}" if config.tags
        options << "--limit=#{as_list_argument(config.limit)}" if config.limit
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

      private

      def as_list_argument(v)
        v.kind_of?(Array) ? v.join(',') : v
      end
    end
  end
end
