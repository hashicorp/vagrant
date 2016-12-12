require_relative "../errors"
require_relative "../helpers"

module VagrantPlugins
  module Ansible
    module Provisioner

      # This class is a base class where the common functionality shared between
      # both Ansible provisioners are stored.
      # This is **not an actual provisioner**.
      # Instead, {Host} (ansible) or {Guest} (ansible_local) should be used.

      class Base < Vagrant.plugin("2", :provisioner)

        RANGE_PATTERN = %r{(?:\[[a-z]:[a-z]\]|\[[0-9]+?:[0-9]+?\])}.freeze

        protected

        def initialize(machine, config)
          super

          @command_arguments = []
          @environment_variables = {}
          @inventory_machines = {}
          @inventory_path = nil
        end

        def check_files_existence
          check_path_is_a_file(config.playbook, :playbook)

          check_path_exists(config.inventory_path, :inventory_path) if config.inventory_path
          check_path_is_a_file(config.config_file, :config_file) if config.config_file
          check_path_is_a_file(config.extra_vars[1..-1], :extra_vars) if has_an_extra_vars_file_argument
          check_path_is_a_file(config.galaxy_role_file, :galaxy_role_file) if config.galaxy_role_file
          check_path_is_a_file(config.vault_password_file, :vault_password_file) if config.vault_password_file
        end

        def get_environment_variables_for_shell_execution
          shell_env_vars = []
          @environment_variables.each_pair do |k, v|
            if k =~ /ANSIBLE_SSH_ARGS|ANSIBLE_ROLES_PATH|ANSIBLE_CONFIG/
              shell_env_vars << "#{k}='#{v}'"
            else
              shell_env_vars << "#{k}=#{v}"
            end
          end
          shell_env_vars
        end

        def ansible_galaxy_command_for_shell_execution
          command_values = {
            role_file: "'#{get_galaxy_role_file}'",
            roles_path: "'#{get_galaxy_roles_path}'"
          }

          shell_command = get_environment_variables_for_shell_execution

          shell_command << config.galaxy_command % command_values

          shell_command.flatten.join(' ')
        end

        def ansible_playbook_command_for_shell_execution
          shell_command = get_environment_variables_for_shell_execution

          shell_command << config.playbook_command

          shell_args = []
          @command_arguments.each do |arg|
            if arg =~ /(--start-at-task|--limit)=(.+)/
              shell_args << %Q(#{$1}="#{$2}")
            elsif arg =~ /(--extra-vars)=(.+)/
              shell_args << %Q(%s="%s") % [$1, $2.gsub('\\', '\\\\\\').gsub('"', %Q(\\"))]
            else
              shell_args << arg
            end
          end

          shell_command << shell_args

          # Add the raw arguments at the end, to give them the highest precedence
          shell_command << config.raw_arguments if config.raw_arguments

          shell_command << config.playbook

          shell_command.flatten.join(' ')
        end

        def prepare_common_command_arguments
          # By default we limit by the current machine,
          # but this can be overridden by the `limit` option.
          if config.limit
            @command_arguments << "--limit=#{Helpers::as_list_argument(config.limit)}"
          else
            @command_arguments << "--limit=#{@machine.name}"
          end

          @command_arguments << "--inventory-file=#{inventory_path}"
          @command_arguments << "--extra-vars=#{extra_vars_argument}" if config.extra_vars
          @command_arguments << "--sudo" if config.sudo
          @command_arguments << "--sudo-user=#{config.sudo_user}" if config.sudo_user
          @command_arguments << "#{verbosity_argument}" if verbosity_is_enabled?
          @command_arguments << "--vault-password-file=#{config.vault_password_file}" if config.vault_password_file
          @command_arguments << "--tags=#{Helpers::as_list_argument(config.tags)}" if config.tags
          @command_arguments << "--skip-tags=#{Helpers::as_list_argument(config.skip_tags)}" if config.skip_tags
          @command_arguments << "--start-at-task=#{config.start_at_task}" if config.start_at_task
        end

        def prepare_common_environment_variables
          # Ensure Ansible output isn't buffered so that we receive output
          # on a task-by-task basis.
          @environment_variables["PYTHONUNBUFFERED"] = 1

          # When Ansible output is piped in Vagrant integration, its default colorization is
          # automatically disabled and the only way to re-enable colors is to use ANSIBLE_FORCE_COLOR.
          @environment_variables["ANSIBLE_FORCE_COLOR"] = "true" if @machine.env.ui.color?
          # Setting ANSIBLE_NOCOLOR is "unnecessary" at the moment, but this could change in the future
          # (e.g. local provisioner [GH-2103], possible change in vagrant/ansible integration, etc.)
          @environment_variables["ANSIBLE_NOCOLOR"] = "true" if !@machine.env.ui.color?

          # Use ANSIBLE_ROLES_PATH to tell ansible-playbook where to look for roles
          # (there is no equivalent command line argument in ansible-playbook)
          @environment_variables["ANSIBLE_ROLES_PATH"] = get_galaxy_roles_path if config.galaxy_roles_path

          prepare_ansible_config_environment_variable
        end

        def prepare_ansible_config_environment_variable
          @environment_variables["ANSIBLE_CONFIG"] = config.config_file if config.config_file
        end

        # Auto-generate "safe" inventory file based on Vagrantfile,
        # unless inventory_path is explicitly provided
        def inventory_path
          if config.inventory_path
            config.inventory_path
          else
            @inventory_path ||= generate_inventory
          end
        end

        def get_inventory_host_vars_string(machine_name)
          # In Ruby, Symbol and String values are different, but
          # Vagrant has to unify them for better user experience.
          vars = config.host_vars[machine_name.to_sym]
          if !vars
            vars = config.host_vars[machine_name.to_s]
          end
          s = nil
          if vars.is_a?(Hash)
            s = vars.each.collect{ |k, v| "#{k}=#{v}" }.join(" ")
          elsif vars.is_a?(Array)
            s = vars.join(" ")
          elsif vars.is_a?(String)
            s = vars
          end
          if s and !s.empty? then s else nil end
        end

        def generate_inventory
          inventory = "# Generated by Vagrant\n\n"

          # This "abstract" step must fill the @inventory_machines list
          # and return the list of supported host(s)
          inventory += generate_inventory_machines

          inventory += generate_inventory_groups

          # This "abstract" step must create the inventory file and
          # return its location path
          # TODO: explain possible race conditions, etc.
          @inventory_path = ship_generated_inventory(inventory)
        end

        # Write out groups information.
        # All defined groups will be included, but only supported
        # machines and defined child groups will be included.
        def generate_inventory_groups
          groups_of_groups = {}
          defined_groups = []
          group_vars = {}
          inventory_groups = ""

          # Verify if host range patterns exist and warn
          if config.groups.any? { |gm| gm.to_s[RANGE_PATTERN] }
            @machine.ui.warn(I18n.t("vagrant.provisioners.ansible.ansible_host_pattern_detected"))
          end

          config.groups.each_pair do |gname, gmembers|
            if gname.is_a?(Symbol)
              gname = gname.to_s
            end

            if gmembers.is_a?(String)
              gmembers = gmembers.split(/\s+/)
            elsif gmembers.is_a?(Hash)
              gmembers = gmembers.each.collect{ |k, v| "#{k}=#{v}" }
            elsif !gmembers.is_a?(Array)
              gmembers = []
            end

            if gname.end_with?(":children")
              groups_of_groups[gname] = gmembers
              defined_groups << gname.sub(/:children$/, '')
            elsif gname.end_with?(":vars")
              group_vars[gname] = gmembers
            else
              defined_groups << gname
              inventory_groups += "\n[#{gname}]\n"
              gmembers.each do |gm|
                # TODO : Expand and validate host range patterns
                # against @inventory_machines list before adding them
                # otherwise abort with an error message
                if gm[RANGE_PATTERN]
                  inventory_groups += "#{gm}\n"
                end
                inventory_groups += "#{gm}\n" if @inventory_machines.include?(gm.to_sym)
              end
            end
          end

          defined_groups.uniq!
          groups_of_groups.each_pair do |gname, gmembers|
            inventory_groups += "\n[#{gname}]\n"
            gmembers.each do |gm|
              inventory_groups += "#{gm}\n" if defined_groups.include?(gm)
            end
          end

          group_vars.each_pair do |gname, gmembers|
            if defined_groups.include?(gname.sub(/:vars$/, ""))
              inventory_groups += "\n[#{gname}]\n" + gmembers.join("\n") + "\n"
            end
          end

          return inventory_groups
        end

        def has_an_extra_vars_file_argument
          config.extra_vars && config.extra_vars.kind_of?(String) && config.extra_vars =~ /^@.+$/
        end

        def extra_vars_argument
          if has_an_extra_vars_file_argument
            # A JSON or YAML file is referenced.
            config.extra_vars
          else
            # Expected to be a Hash after config validation.
            config.extra_vars.to_json
          end
        end

        def get_galaxy_role_file
          Helpers::expand_path_in_unix_style(config.galaxy_role_file, get_provisioning_working_directory)
        end

        def get_galaxy_roles_path
          base_dir = get_provisioning_working_directory
          if config.galaxy_roles_path
            Helpers::expand_path_in_unix_style(config.galaxy_roles_path, base_dir)
          else
            playbook_path = Helpers::expand_path_in_unix_style(config.playbook, base_dir)
            File.join(Pathname.new(playbook_path).parent, 'roles')
          end
        end

        def ui_running_ansible_command(name, command)
          @machine.ui.detail I18n.t("vagrant.provisioners.ansible.running_#{name}")
          if verbosity_is_enabled?
            # Show the ansible command in use
            @machine.env.ui.detail command
          end
        end

        def verbosity_is_enabled?
          config.verbose && !config.verbose.to_s.empty?
        end

        def verbosity_argument
          if config.verbose.to_s =~ /^-?(v+)$/
            "-#{$+}"
          else
            # safe default, in case input strays
            '-v'
          end
        end

      end
    end
  end
end
