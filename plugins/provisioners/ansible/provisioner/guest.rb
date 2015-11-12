require 'tempfile'

require_relative "base"

module VagrantPlugins
  module Ansible
    module Provisioner
      class Guest < Base

        def initialize(machine, config)
          super
          @logger = Log4r::Logger.new("vagrant::provisioners::ansible_guest")
        end

        def provision
          check_and_install_ansible
          prepare_common_command_arguments
          prepare_common_environment_variables
          execute_ansible_playbook_on_guest
        end

        protected

        #
        # This handles verifying the Ansible installation, installing it if it was
        # requested, and so on. This method will raise exceptions if things are wrong.
        #
        # Current limitations:
        #   - The installation of a specific Ansible version is not supported.
        #     Such feature is difficult to systematically provide via package repositories (apt, yum, ...).
        #     Installing via pip python packaging or directly from github source would be appropriate,
        #     but these approaches require more dependency burden.
        #   - There is no guarantee that the automated installation will replace
        #     a previous Ansible installation.
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
            @machine.ui.detail(I18n.t("vagrant.provisioners.ansible.installing"))
            @machine.guest.capability(:ansible_install)
          end

          # Check for the existence of ansible-playbook binary on the guest,
          @machine.communicate.execute(
            "ansible-playbook --help",
            :error_class => Ansible::Errors::AnsibleError,
            :error_key => :ansible_playbook_app_not_found_on_guest)

          # Check if requested ansible version is available
          if (!config.version.empty? &&
              config.version.to_s.to_sym != :latest &&
              !@machine.guest.capability(:ansible_installed, config.version))
            raise Ansible::Errors::AnsibleVersionNotFoundOnGuest, required_version: config.version.to_s
          end
        end

        def execute_ansible_playbook_on_guest
          command = (%w(ansible-playbook) << @command_arguments << config.playbook).flatten
          remote_command = "cd #{config.provisioning_path} && #{Helpers::stringify_ansible_playbook_command(@environment_variables, command)}"

          # TODO: generic HOOK ???    
          # Show the ansible command in use
          if verbosity_is_enabled?
            @machine.env.ui.detail(remote_command)
          end

          result = execute_on_guest(remote_command)
          raise Ansible::Errors::AnsiblePlaybookAppFailed if result != 0
        end

        def execute_on_guest(command)
          @machine.communicate.execute(command, :error_check => false) do |type, data|
            if [:stderr, :stdout].include?(type)
              @machine.env.ui.info(data, :new_line => false, :prefix => false)
            end
          end
        end

        def ship_generated_inventory(inventory_content)
          inventory_basedir = File.join(config.tmp_path, "inventory")
          inventory_path = File.join(inventory_basedir, "vagrant_ansible_local_inventory")

          temp_inventory = Tempfile.new("vagrant_ansible_local_inventory_#{@machine.name}")
          temp_inventory.write(inventory_content)
          temp_inventory.close

          create_and_chown_remote_folder(inventory_basedir)
          @machine.communicate.tap do |comm|
            comm.sudo("rm -f #{inventory_path}", error_check: false)
            comm.upload(temp_inventory.path, inventory_path)
          end

          return inventory_path
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

      end
    end
  end
end
