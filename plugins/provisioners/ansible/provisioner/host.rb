require "thread"

require_relative "base"

module VagrantPlugins
  module Ansible
    module Provisioner
      class Host < Base

        @@lock = Mutex.new

        def initialize(machine, config)
          super
          @control_machine = "host"
          @logger = Log4r::Logger.new("vagrant::provisioners::ansible_host")
        end

        def provision
          # At this stage, the SSH access is guaranteed to be ready
          @ssh_info = @machine.ssh_info

          warn_for_unsupported_platform
          check_files_existence
          check_ansible_version_and_compatibility

          execute_ansible_galaxy_from_host if config.galaxy_role_file
          execute_ansible_playbook_from_host
        end

        protected

        VAGRANT_ARG_SEPARATOR = 'VAGRANT_ARG_SEP'

        def warn_for_unsupported_platform
          if Vagrant::Util::Platform.windows?
            @machine.env.ui.warn(I18n.t("vagrant.provisioners.ansible.windows_not_supported_for_control_machine") + "\n")
          end
        end

        def check_ansible_version_and_compatibility
          # This step will also fetch the Ansible version data into related instance variables
          set_and_check_compatibility_mode

          # Skip this check when not required, nor possible
          if !@gathered_version || config.version.empty? || config.version.to_s.to_sym == :latest
            return
          end

          if config.version != @gathered_version
            raise Ansible::Errors::AnsibleVersionMismatch,
              system: @control_machine,
              required_version: config.version,
              current_version: @gathered_version
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
            # the ansible_ssh_user/ansible_user parameter won't be added to the auto-generated inventory.
            @command_arguments << "--user=#{@ssh_info[:username]}"
          elsif config.inventory_path
            # Using an extra variable is the only way to ensure that the Ansible remote user
            # is overridden (as the ansible inventory is not under vagrant control)
            @command_arguments << "--extra-vars=#{@lexicon[:ansible_user]}='#{@ssh_info[:username]}'"
          end

          @command_arguments << "--#{@lexicon[:ask_become_pass]}" if config.ask_become_pass
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

        def execute_command_from_host(command)
          begin
            result = Vagrant::Util::Subprocess.execute(*command) do |type, data|
              if type == :stdout || type == :stderr
                @machine.env.ui.detail(data, new_line: false, prefix: false)
              end
            end
            raise Ansible::Errors::AnsibleCommandFailed if result.exit_code != 0
          rescue Vagrant::Errors::CommandUnavailable
            raise Ansible::Errors::AnsibleNotFoundOnHost
          end
        end

        def gather_ansible_version
          raw_output = ""
          command = %w(ansible --version)

          command << {
            notify: [:stdout, :stderr]
          }

          begin
            result = Vagrant::Util::Subprocess.execute(*command) do |type, output|
              if type == :stdout && output.lines[0]
                raw_output = output
              end
            end
            if result.exit_code != 0
              raw_output = ""
            end
          rescue Vagrant::Errors::CommandUnavailable
            raise Ansible::Errors::AnsibleNotFoundOnHost
          end

          raw_output
        end

        def execute_ansible_galaxy_from_host
          prepare_ansible_config_environment_variable

          command_values = {
            role_file: get_galaxy_role_file,
            roles_path: get_galaxy_roles_path
          }
          command_template = config.galaxy_command.gsub(' ', VAGRANT_ARG_SEPARATOR)
          str_command = command_template % command_values

          command = str_command.split(VAGRANT_ARG_SEPARATOR)
          command << {
            env: @environment_variables,
            # Write stdout and stderr data, since it's the regular Ansible output
            notify: [:stdout, :stderr],
            workdir: @machine.env.root_path.to_s
          }

          ui_running_ansible_command "galaxy", ansible_galaxy_command_for_shell_execution

          execute_command_from_host command
        end

        def execute_ansible_playbook_from_host
          prepare_environment_variables
          prepare_command_arguments

          # Assemble the full ansible-playbook command
          command = [config.playbook_command] << @command_arguments

          # Add the raw arguments at the end, to give them the highest precedence
          command << config.raw_arguments if config.raw_arguments

          command << config.playbook
          command = command.flatten

          command << {
            env: @environment_variables,
            # Write stdout and stderr data, since it's the regular Ansible output
            notify: [:stdout, :stderr],
            workdir: @machine.env.root_path.to_s
          }

          ui_running_ansible_command "playbook", ansible_playbook_command_for_shell_execution

          execute_command_from_host command
        end

        def ship_generated_inventory(inventory_content)
          inventory_path = Pathname.new(File.join(@machine.env.local_data_path.join, %w(provisioners ansible inventory)))
          FileUtils.mkdir_p(inventory_path) unless File.directory?(inventory_path)

          inventory_file = Pathname.new(File.join(inventory_path, 'vagrant_ansible_inventory'))
          @@lock.synchronize do
            if !File.exists?(inventory_file) or inventory_content != File.read(inventory_file)
              begin
                # ansible dir inventory will ignore files starting with '.'
                inventory_tmpfile = Tempfile.new('.vagrant_ansible_inventory', inventory_path)
                inventory_tmpfile.write(inventory_content)
                inventory_tmpfile.close
                File.rename(inventory_tmpfile.path, inventory_file)
              ensure
                inventory_tmpfile.close
                inventory_tmpfile.unlink
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

              # Call only once the SSH and WinRM info computation
              # Note that machines configured with WinRM communicator, also have a "partial" ssh_info.
              m_ssh_info = m.ssh_info
              host_vars = get_inventory_host_vars_string(m.name)
              if m.config.vm.communicator == :winrm
                m_winrm_net_info = CommunicatorWinRM::Helper.winrm_info(m) # can raise a WinRMNotReady exception...
                machines += get_inventory_winrm_machine(m, m_winrm_net_info)
                machines.sub!(/\n$/, " #{host_vars}\n") if host_vars
                @inventory_machines[m.name] = m
              elsif !m_ssh_info.nil?
                machines += get_inventory_ssh_machine(m, m_ssh_info)
                machines.sub!(/\n$/, " #{host_vars}\n") if host_vars
                @inventory_machines[m.name] = m
              else
                @logger.error("Auto-generated inventory: Impossible to get SSH information for machine '#{m.name} (#{m.provider_name})'. This machine should be recreated.")
                # Let a note about this missing machine
                machines += "# MISSING: '#{m.name}' machine was probably removed without using Vagrant. This machine should be recreated.\n"
              end
            rescue Vagrant::Errors::MachineNotFound, CommunicatorWinRM::Errors::WinRMNotReady => e
              @logger.info("Auto-generated inventory: Skip machine '#{am[0]} (#{am[1]})', which is not configured for this Vagrant environment.")
            end
          end

          return machines
        end

        def get_provisioning_working_directory
          machine.env.root_path
        end

        def get_inventory_ssh_machine(machine, ssh_info)
          forced_remote_user = ""
          if config.force_remote_user
            forced_remote_user = "#{@lexicon[:ansible_user]}='#{ssh_info[:username]}' "
          end

          "#{machine.name} #{@lexicon[:ansible_host]}=#{ssh_info[:host]} #{@lexicon[:ansible_port]}=#{ssh_info[:port]} #{forced_remote_user}ansible_ssh_private_key_file='#{ssh_info[:private_key_path][0]}'\n"
        end

        def get_inventory_winrm_machine(machine, winrm_net_info)
          forced_remote_user = ""
          if config.force_remote_user
            forced_remote_user = "#{@lexicon[:ansible_user]}='#{machine.config.winrm.username}' "
          end

          "#{machine.name} ansible_connection=winrm #{@lexicon[:ansible_host]}=#{winrm_net_info[:host]} #{@lexicon[:ansible_port]}=#{winrm_net_info[:port]} #{forced_remote_user}#{@lexicon[:ansible_password]}='#{machine.config.winrm.password}'\n"
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
            # TODO ssh_options << "-o ProxyCommand=\"#{ proxy_cmd }\""
          end

          # Use an SSH ProxyCommand when corresponding Vagrant setting is defined
          if @machine.ssh_info[:proxy_command]
            proxy_cmd = @machine.ssh_info[:proxy_command]
            ssh_options << "-o ProxyCommand='#{ proxy_cmd }'"
          end

          # Don't access user's known_hosts file, except when host_key_checking is enabled.
          ssh_options << "-o UserKnownHostsFile=/dev/null" unless config.host_key_checking

          # Compare to lib/vagrant/util/ssh.rb
          ssh_options << "-o IdentitiesOnly=yes" if !Vagrant::Util::Platform.solaris? && @ssh_info[:keys_only]

          # Multiple Private Keys
          unless !config.inventory_path && @ssh_info[:private_key_path].size == 1
            @ssh_info[:private_key_path].each do |key|
              ssh_options += ["-o", "IdentityFile=%s" % [key.gsub('%', '%%')]]
            end
          end

          # SSH Forwarding
          ssh_options << "-o ForwardAgent=yes" if @ssh_info[:forward_agent]

          # Unchecked SSH Parameters
          ssh_options.concat(config.raw_ssh_args) if config.raw_ssh_args

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

        def check_path(path, path_test_method, option_name)
          # Checks for the existence of given file (or directory) on the host system,
          # and error if it doesn't exist.

          expanded_path = Pathname.new(path).expand_path(@machine.env.root_path)
          if !expanded_path.public_send(path_test_method)
            raise Ansible::Errors::AnsibleError,
                  _key: :config_file_not_found,
                  config_option: option_name,
                  path: expanded_path,
                  system: @control_machine
          end
        end

        def check_path_is_a_file(path, option_name)
          check_path(path, "file?", option_name)
        end

        def check_path_exists(path, option_name)
          check_path(path, "exist?", option_name)
        end

      end
    end
  end
end
