require "vagrant/util/platform"
require "thread"

module VagrantPlugins
  module Ansible
    class Provisioner < Vagrant.plugin("2", :provisioner)

      @@lock = Mutex.new

      def initialize(machine, config)
        super

        @logger = Log4r::Logger.new("vagrant::provisioners::ansible")
      end

      def provision
        @ssh_info = @machine.ssh_info

        #
        # Ansible provisioner options
        #

        # By default, connect with Vagrant SSH username
        options = %W[--user=#{@ssh_info[:username]}]

        # Connect with native OpenSSH client
        # Other modes (e.g. paramiko) are not officially supported,
        # but can be enabled via raw_arguments option.
        options << "--connection=ssh"

        # Increase the SSH connection timeout, as the Ansible default value (10 seconds)
        # is a bit demanding for some overloaded developer boxes. This is particularly
        # helpful when additional virtual networks are configured, as their availability
        # is not controlled during vagrant boot process.
        options << "--timeout=30"

        # By default we limit by the current machine, but
        # this can be overridden by the `limit` option.
        if config.limit
          options << "--limit=#{as_list_argument(config.limit)}"
        else
          options << "--limit=#{@machine.name}"
        end

        options << "--inventory-file=#{self.setup_inventory_file}"
        options << "--extra-vars=#{self.get_extra_vars_argument}" if config.extra_vars
        options << "--sudo" if config.sudo
        options << "--sudo-user=#{config.sudo_user}" if config.sudo_user
        options << "#{self.get_verbosity_argument}" if config.verbose
        options << "--ask-sudo-pass" if config.ask_sudo_pass
        options << "--ask-vault-pass" if config.ask_vault_pass
        options << "--vault-password-file=#{config.vault_password_file}" if config.vault_password_file
        options << "--tags=#{as_list_argument(config.tags)}" if config.tags
        options << "--skip-tags=#{as_list_argument(config.skip_tags)}" if config.skip_tags
        options << "--start-at-task=#{config.start_at_task}" if config.start_at_task

        # Finally, add the raw configuration options, which has the highest precedence
        # and can therefore potentially override any other options of this provisioner.
        options.concat(self.as_array(config.raw_arguments)) if config.raw_arguments

        #
        # Assemble the full ansible-playbook command
        #

        command = (%w(ansible-playbook) << options << config.playbook).flatten

        env = {
          # Ensure Ansible output isn't buffered so that we receive output
          # on a task-by-task basis.
          "PYTHONUNBUFFERED" => 1,

          # Some Ansible options must be passed as environment variables,
          # as there is no equivalent command line arguments
          "ANSIBLE_HOST_KEY_CHECKING" => "#{config.host_key_checking}",
        }

        # When Ansible output is piped in Vagrant integration, its default colorization is
        # automatically disabled and the only way to re-enable colors is to use ANSIBLE_FORCE_COLOR.
        env["ANSIBLE_FORCE_COLOR"] = "true" if @machine.env.ui.color?
        # Setting ANSIBLE_NOCOLOR is "unnecessary" at the moment, but this could change in the future
        # (e.g. local provisioner [GH-2103], possible change in vagrant/ansible integration, etc.)
        env["ANSIBLE_NOCOLOR"] = "true" if !@machine.env.ui.color?

        # ANSIBLE_SSH_ARGS is required for Multiple SSH keys, SSH forwarding and custom SSH settings
        env["ANSIBLE_SSH_ARGS"] = ansible_ssh_args unless ansible_ssh_args.empty?

        show_ansible_playbook_command(env, command) if config.verbose

        # Write stdout and stderr data, since it's the regular Ansible output
        command << {
          env: env,
          notify: [:stdout, :stderr],
          workdir: @machine.env.root_path.to_s
        }

        begin
          result = Vagrant::Util::Subprocess.execute(*command) do |type, data|
            if type == :stdout || type == :stderr
              @machine.env.ui.info(data, new_line: false, prefix: false)
            end
          end

          raise Vagrant::Errors::AnsibleFailed if result.exit_code != 0
        rescue Vagrant::Util::Subprocess::LaunchError
          raise Vagrant::Errors::AnsiblePlaybookAppNotFound
        end
      end

      protected

      # Auto-generate "safe" inventory file based on Vagrantfile,
      # unless inventory_path is explicitly provided
      def setup_inventory_file
        return config.inventory_path if config.inventory_path

        # Managed machines
        inventory_machines = {}

        generated_inventory_dir = @machine.env.local_data_path.join(File.join(%w(provisioners ansible inventory)))
        FileUtils.mkdir_p(generated_inventory_dir) unless File.directory?(generated_inventory_dir)
        generated_inventory_file = generated_inventory_dir.join('vagrant_ansible_inventory')

        inventory = "# Generated by Vagrant\n\n"

        @machine.env.active_machines.each do |am|
          begin
            m = @machine.env.machine(*am)
            m_ssh_info = m.ssh_info
            if !m_ssh_info.nil?
              inventory += "#{m.name} ansible_ssh_host=#{m_ssh_info[:host]} ansible_ssh_port=#{m_ssh_info[:port]} ansible_ssh_private_key_file=#{m_ssh_info[:private_key_path][0]}\n"
              inventory_machines[m.name] = m
            else
              @logger.error("Auto-generated inventory: Impossible to get SSH information for machine '#{m.name} (#{m.provider_name})'. This machine should be recreated.")
              # Let a note about this missing machine
              inventory += "# MISSING: '#{m.name}' machine was probably removed without using Vagrant. This machine should be recreated.\n"
            end
          rescue Vagrant::Errors::MachineNotFound => e
            @logger.info("Auto-generated inventory: Skip machine '#{am[0]} (#{am[1]})', which is not configured for this Vagrant environment.")
          end
        end

        # Write out groups information.
        # All defined groups will be included, but only supported
        # machines and defined child groups will be included.
        # Group variables are intentionally skipped.
        groups_of_groups = {}
        defined_groups = []

        config.groups.each_pair do |gname, gmembers|
          # Require that gmembers be an array
          # (easier to be tolerant and avoid error management of few value)
          gmembers = [gmembers] if !gmembers.is_a?(Array)

          if gname.end_with?(":children")
            groups_of_groups[gname] = gmembers
            defined_groups << gname.sub(/:children$/, '')
          elsif !gname.include?(':vars')
          defined_groups << gname
          inventory += "\n[#{gname}]\n"
            gmembers.each do |gm|
              inventory += "#{gm}\n" if inventory_machines.include?(gm.to_sym)
            end
          end
        end

        defined_groups.uniq!
        groups_of_groups.each_pair do |gname, gmembers|
          inventory += "\n[#{gname}]\n"
          gmembers.each do |gm|
            inventory += "#{gm}\n" if defined_groups.include?(gm)
          end
        end

        @@lock.synchronize do
          if ! File.exists?(generated_inventory_file) or
             inventory != File.read(generated_inventory_file)

            generated_inventory_file.open('w') do |file|
              file.write(inventory)
            end
          end
        end

        return generated_inventory_dir.to_s
      end

      def get_extra_vars_argument
        if config.extra_vars.kind_of?(String) and config.extra_vars =~ /^@.+$/
          # A JSON or YAML file is referenced (requires Ansible 1.3+)
          return config.extra_vars
        else
          # Expected to be a Hash after config validation. (extra_vars as
          # JSON requires Ansible 1.2+, while YAML requires Ansible 1.3+)
          return config.extra_vars.to_json
        end
      end

      def get_verbosity_argument
        if config.verbose.to_s =~ /^v+$/
          # ansible-playbook accepts "silly" arguments like '-vvvvv' as '-vvvv' for now
          return "-#{config.verbose}"
        else
          # safe default, in case input strays
          return '-v'
        end
      end

      def ansible_ssh_args
        @ansible_ssh_args ||= get_ansible_ssh_args
      end

      # Use ANSIBLE_SSH_ARGS to pass some OpenSSH options that are not wrapped by
      # an ad-hoc Ansible option. Last update corresponds to Ansible 1.8
      def get_ansible_ssh_args
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
        ssh_options.concat(self.as_array(config.raw_ssh_args)) if config.raw_ssh_args

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

      def as_list_argument(v)
        v.kind_of?(Array) ? v.join(',') : v
      end

      def as_array(v)
        v.kind_of?(Array) ? v : [v]
      end

      def show_ansible_playbook_command(env, command)
        shell_command = ''
        env.each_pair do |k, v|
          if k == 'ANSIBLE_SSH_ARGS'
            shell_command += "#{k}='#{v}' "
          else
            shell_command += "#{k}=#{v} "
          end
        end

        shell_arg = []
        command.each do |arg|
          if arg =~ /(--start-at-task|--limit)=(.+)/
            shell_arg << "#{$1}='#{$2}'"
          else
            shell_arg << arg
          end
        end

        shell_command += shell_arg.join(' ')

        @machine.env.ui.detail(shell_command)
      end
    end
  end
end
