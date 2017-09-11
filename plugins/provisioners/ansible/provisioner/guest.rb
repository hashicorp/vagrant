require "tempfile"

require_relative "base"

module VagrantPlugins
  module Ansible
    module Provisioner
      class Guest < Base
        include Vagrant::Util

        def initialize(machine, config)
          super
          @control_machine = "guest"
          @logger = Log4r::Logger.new("vagrant::provisioners::ansible_guest")
        end

        def provision
          check_files_existence
          check_and_install_ansible

          execute_ansible_galaxy_on_guest if config.galaxy_role_file
          execute_ansible_playbook_on_guest
        end

        protected

        #
        # This handles verifying the Ansible installation, installing it if it was
        # requested, and so on. This method will raise exceptions if things are wrong.
        # The compatibility mode checks are also performed here in order to fetch the
        # Ansible version information only once.
        #
        # Current limitations:
        #   - The installation of a specific Ansible version is only supported by
        #     the "pip" install_mode.
        #   - There is no absolute guarantee that the automated installation will replace
        #     a previous Ansible installation (although it works fine in many cases)
        #
        def check_and_install_ansible
          @logger.info("Checking for Ansible installation...")

          # If the guest cannot check if Ansible is installed,
          # print a warning and try to continue without any installation attempt...
          if !@machine.guest.capability?(:ansible_installed)
            @machine.ui.warn(I18n.t("vagrant.provisioners.ansible.cannot_detect"))
            return
          end

          # Try to install Ansible (if needed and requested)
          if config.install &&
             (config.version.to_s.to_sym == :latest ||
              !@machine.guest.capability(:ansible_installed, config.version))
            @machine.ui.detail I18n.t("vagrant.provisioners.ansible.installing")
            @machine.guest.capability(:ansible_install, config.install_mode, config.version, config.pip_args)
          end

          # This step will also fetch the Ansible version data into related instance variables
          set_and_check_compatibility_mode

          # Check if requested ansible version is available
          if (!config.version.empty? &&
              config.version.to_s.to_sym != :latest &&
              config.version != @gathered_version)
            raise Ansible::Errors::AnsibleVersionMismatch,
              system: @control_machine,
              required_version: config.version,
              current_version: @gathered_version
          end
        end

        def gather_ansible_version
          raw_output = ""

          result = @machine.communicate.execute(
            "ansible --version",
            error_class: Ansible::Errors::AnsibleNotFoundOnGuest,
            error_key: :ansible_not_found_on_guest) do |type, output|
            if type == :stdout && output.lines[0]
              raw_output = output.lines[0]
            end
          end

          if result != 0
            raw_output = ""
          end

          raw_output
        end

        def get_provisioning_working_directory
          config.provisioning_path
        end

        def execute_ansible_galaxy_on_guest
          prepare_ansible_config_environment_variable

          execute_ansible_command_on_guest "galaxy", ansible_galaxy_command_for_shell_execution
        end

        def execute_ansible_playbook_on_guest
          prepare_common_command_arguments
          prepare_common_environment_variables

          execute_ansible_command_on_guest "playbook", ansible_playbook_command_for_shell_execution
        end

        def execute_ansible_command_on_guest(name, command)
          remote_command = "cd #{config.provisioning_path} && #{command}"

          ui_running_ansible_command name, remote_command

          result = execute_on_guest(remote_command)
          raise Ansible::Errors::AnsibleCommandFailed if result != 0
        end

        def execute_on_guest(command)
          @machine.communicate.execute(command, error_check: false) do |type, data|
            if [:stderr, :stdout].include?(type)
              @machine.env.ui.info(data, new_line: false, prefix: false)
            end
          end
        end

        def ship_generated_inventory(inventory_content)
          inventory_basedir = File.join(config.tmp_path, "inventory")
          inventory_path = File.join(inventory_basedir, "vagrant_ansible_local_inventory")

          create_and_chown_remote_folder(inventory_basedir)
          @machine.communicate.sudo("rm -f #{inventory_path}", error_check: false)

          Tempfile.open("vagrant-ansible-local-inventory-#{@machine.name}") do |f|
            f.binmode
            f.write(inventory_content)
            f.fsync
            f.close
            @machine.communicate.upload(f.path, inventory_path)
          end

          return inventory_basedir
        end

        def generate_inventory_machines
          machines = ""

          # TODO: Instead, why not loop over active_machines and skip missing guests, like in Host?
          machine.env.machine_names.each do |machine_name|
            begin
              @inventory_machines[machine_name] = machine_name
              if @machine.name == machine_name
                machines += "#{machine_name} ansible_connection=local\n"
              else
                machines += "#{machine_name}\n"
              end
              host_vars = get_inventory_host_vars_string(machine_name)
              machines.sub!(/\n$/, " #{host_vars}\n") if host_vars
            end
          end

          return machines
        end

        def create_and_chown_remote_folder(path)
          @machine.communicate.tap do |comm|
            comm.sudo("mkdir -p #{path}")
            comm.sudo("chown -h #{@machine.ssh_info[:username]} #{path}")
          end
        end

        def check_path(path, test_args, option_name)
          # Checks for the existence of given file (or directory) on the guest system,
          # and error if it doesn't exist.

          remote_path = Helpers::expand_path_in_unix_style(path, config.provisioning_path)
          command = "test #{test_args} '#{remote_path}'"

          @machine.communicate.execute(
            command,
            error_class: Ansible::Errors::AnsibleError,
            error_key: :config_file_not_found,
            config_option: option_name,
            path: remote_path,
            system: @control_machine
          )
        end

        def check_path_is_a_file(path, error_message_key)
          check_path(path, "-f", error_message_key)
        end

        def check_path_exists(path, error_message_key)
          check_path(path, "-e", error_message_key)
        end

      end
    end
  end
end
