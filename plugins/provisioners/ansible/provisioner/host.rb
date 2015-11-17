require "thread"

require_relative "base"

module VagrantPlugins
  module Ansible
    module Provisioner
      class Host < Base

        @@lock = Mutex.new

        def initialize(machine, config)
          super
          @logger = Log4r::Logger.new("vagrant::provisioners::ansible_host")
        end

        def provision
          # At this stage, the SSH access is guaranteed to be ready
          @ssh_info = @machine.ssh_info

          warn_for_unsupported_platform
          prepare_command_arguments
          prepare_environment_variables
          execute_ansible_playbook_from_host
        end

        protected

        def warn_for_unsupported_platform
          if Vagrant::Util::Platform.windows?
            @machine.env.ui.warn(I18n.t("vagrant.provisioners.ansible.windows_not_supported_for_control_machine"))
          end
        end

        def prepare_command_arguments
          # Connect with native OpenSSH client
          # Other modes (e.g. paramiko) are not officially supported,
          # but can be enabled via raw_arguments option.
          @command_arguments << "--connection=ssh"

          # Increase the SSH connection timeout, as the Ansible default value (10 seconds)
          # is a bit demanding for some overloaded developer boxes. This is particularly
          # helpful when additional virtual networks are configured, as their availability
          # is not controlled during vagrant boot process.
          @command_arguments << "--timeout=30"

          if !config.force_remote_user
            # Pass the vagrant ssh username as Ansible default remote user, because
            # the ansible_ssh_user parameter won't be added to the auto-generated inventory.
            @command_arguments << "--user=#{@ssh_info[:username]}"
          elsif config.inventory_path
            # Using an extra variable is the only way to ensure that the Ansible remote user
            # is overridden (as the ansible inventory is not under vagrant control)
            @command_arguments << "--extra-vars=ansible_ssh_user='#{@ssh_info[:username]}'"
          end

          @command_arguments << "--ask-sudo-pass" if config.ask_sudo_pass
          @command_arguments << "--ask-vault-pass" if config.ask_vault_pass

          prepare_common_command_arguments
        end


        def prepare_environment_variables
          prepare_common_environment_variables

          # Some Ansible options must be passed as environment variables,
          # as there is no equivalent command line arguments
          @environment_variables["ANSIBLE_HOST_KEY_CHECKING"] = "#{config.host_key_checking}"

          # ANSIBLE_SSH_ARGS is required for Multiple SSH keys, SSH forwarding and custom SSH settings
          @environment_variables["ANSIBLE_SSH_ARGS"] = ansible_ssh_args unless ansible_ssh_args.empty?
        end

        def execute_ansible_playbook_from_host
          # Assemble the full ansible-playbook command
          command = (%w(ansible-playbook) << @command_arguments << config.playbook).flatten

          # TODO: generic HOOK ???    
          # Show the ansible command in use
          if verbosity_is_enabled?
            @machine.env.ui.detail(Helpers::stringify_ansible_playbook_command(@environment_variables, command))
          end

          # Write stdout and stderr data, since it's the regular Ansible output
          command << {
            env: @environment_variables,
            notify: [:stdout, :stderr],
            workdir: @machine.env.root_path.to_s
          }

          begin
            result = Vagrant::Util::Subprocess.execute(*command) do |type, data|
              if type == :stdout || type == :stderr
                @machine.env.ui.info(data, new_line: false, prefix: false)
              end
            end
            raise Ansible::Errors::AnsiblePlaybookAppFailed if result.exit_code != 0
          rescue Vagrant::Errors::CommandUnavailable
            raise Ansible::Errors::AnsibleNotFoundOnHost
          end
        end

        def ship_generated_inventory(inventory_content)
          inventory_path = Pathname.new(File.join(@machine.env.local_data_path.join, %w(provisioners ansible inventory)))
          FileUtils.mkdir_p(inventory_path) unless File.directory?(inventory_path)

          inventory_file = Pathname.new(File.join(inventory_path, 'vagrant_ansible_inventory'))
          @@lock.synchronize do
            if !File.exists?(inventory_file) or inventory_content != File.read(inventory_file)
              inventory_file.open('w') do |file|
                file.write(inventory_content)
              end
            end
          end

          return inventory_path
        end

        def generate_inventory_machines
          machines = ""

          @machine.env.active_machines.each do |am|
            begin
              m = @machine.env.machine(*am)
              m_ssh_info = m.ssh_info
              if !m_ssh_info.nil?
                forced_ssh_user = ""
                if config.force_remote_user
                  forced_ssh_user = "ansible_ssh_user='#{m_ssh_info[:username]}' "
                end
                machines += "#{m.name} ansible_ssh_host=#{m_ssh_info[:host]} ansible_ssh_port=#{m_ssh_info[:port]} #{forced_ssh_user}ansible_ssh_private_key_file='#{m_ssh_info[:private_key_path][0]}'\n"
                @inventory_machines[m.name] = m
              else
                @logger.error("Auto-generated inventory: Impossible to get SSH information for machine '#{m.name} (#{m.provider_name})'. This machine should be recreated.")
                # Let a note about this missing machine
                machines += "# MISSING: '#{m.name}' machine was probably removed without using Vagrant. This machine should be recreated.\n"
              end
            rescue Vagrant::Errors::MachineNotFound => e
              @logger.info("Auto-generated inventory: Skip machine '#{am[0]} (#{am[1]})', which is not configured for this Vagrant environment.")
            end
          end

          return machines
        end

        def ansible_ssh_args
          @ansible_ssh_args ||= prepare_ansible_ssh_args
        end

        def prepare_ansible_ssh_args
          ssh_options = []

          # Use an SSH ProxyCommand when using the Docker provider with the intermediate host
          if @machine.provider_name == :docker && machine.provider.host_vm?
            docker_host_ssh_info = machine.provider.host_vm.ssh_info

            proxy_cmd = "ssh #{docker_host_ssh_info[:username]}@#{docker_host_ssh_info[:host]}" +
              " -p #{docker_host_ssh_info[:port]} -i #{docker_host_ssh_info[:private_key_path][0]}"

            # Use same options than plugins/providers/docker/communicator.rb
            # Note: this could be improved (DRY'ed) by sharing these settings.
            proxy_cmd += " -o Compression=yes -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

            proxy_cmd += " -o ForwardAgent=yes" if @ssh_info[:forward_agent]

            proxy_cmd += " exec nc %h %p 2>/dev/null"

            ssh_options << "-o ProxyCommand='#{ proxy_cmd }'"
          end

          # Don't access user's known_hosts file, except when host_key_checking is enabled.
          ssh_options << "-o UserKnownHostsFile=/dev/null" unless config.host_key_checking

          # Set IdentitiesOnly=yes to avoid authentication errors when the host has more than 5 ssh keys.
          # Notes:
          #  - Solaris/OpenSolaris/Illumos uses SunSSH which doesn't support the IdentitiesOnly option.
          #  - this could be improved by sharing logic with lib/vagrant/util/ssh.rb
          ssh_options << "-o IdentitiesOnly=yes" unless Vagrant::Util::Platform.solaris?

          # Multiple Private Keys
          unless !config.inventory_path && @ssh_info[:private_key_path].size == 1
            @ssh_info[:private_key_path].each do |key|
              ssh_options << "-o IdentityFile=#{key}"
            end
          end

          # SSH Forwarding
          ssh_options << "-o ForwardAgent=yes" if @ssh_info[:forward_agent]

          # Unchecked SSH Parameters
          ssh_options.concat(Helpers::as_array(config.raw_ssh_args)) if config.raw_ssh_args

          # Re-enable ControlPersist Ansible defaults,
          # which are lost when ANSIBLE_SSH_ARGS is defined.
          unless ssh_options.empty?
            ssh_options << "-o ControlMaster=auto"
            ssh_options << "-o ControlPersist=60s"
            # Intentionally keep ControlPath undefined to let ansible-playbook
            # automatically sets this option to Ansible default value
          end

          ssh_options.join(' ')
        end

      end
    end
  end
end
