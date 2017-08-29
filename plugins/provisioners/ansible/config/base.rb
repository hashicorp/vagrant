require_relative "../constants"

module VagrantPlugins
  module Ansible
    module Config
      class Base < Vagrant.plugin("2", :config)

        GALAXY_COMMAND_DEFAULT = "ansible-galaxy install --role-file=%{role_file} --roles-path=%{roles_path} --force".freeze
        PLAYBOOK_COMMAND_DEFAULT = "ansible-playbook".freeze

        attr_accessor :become
        attr_accessor :become_user
        attr_accessor :compatibility_mode
        attr_accessor :config_file
        attr_accessor :extra_vars
        attr_accessor :galaxy_role_file
        attr_accessor :galaxy_roles_path
        attr_accessor :galaxy_command
        attr_accessor :groups
        attr_accessor :host_vars
        attr_accessor :inventory_path
        attr_accessor :limit
        attr_accessor :playbook
        attr_accessor :playbook_command
        attr_accessor :raw_arguments
        attr_accessor :skip_tags
        attr_accessor :start_at_task
        attr_accessor :tags
        attr_accessor :vault_password_file
        attr_accessor :verbose
        attr_accessor :version

        #
        # Deprecated options
        #
        alias :sudo :become
        def sudo=(value)
          show_deprecation_info 'sudo', 'become'
          @become = value
        end
        alias :sudo_user :become_user
        def sudo_user=(value)
          show_deprecation_info 'sudo_user', 'become_user'
          @become_user = value
        end

        def initialize
          @become              = UNSET_VALUE
          @become_user         = UNSET_VALUE
          @compatibility_mode  = Ansible::COMPATIBILITY_MODE_AUTO
          @config_file         = UNSET_VALUE
          @extra_vars          = UNSET_VALUE
          @galaxy_role_file    = UNSET_VALUE
          @galaxy_roles_path   = UNSET_VALUE
          @galaxy_command      = UNSET_VALUE
          @groups              = UNSET_VALUE
          @host_vars           = UNSET_VALUE
          @inventory_path      = UNSET_VALUE
          @limit               = UNSET_VALUE
          @playbook            = UNSET_VALUE
          @playbook_command    = UNSET_VALUE
          @raw_arguments       = UNSET_VALUE
          @skip_tags           = UNSET_VALUE
          @start_at_task       = UNSET_VALUE
          @tags                = UNSET_VALUE
          @vault_password_file = UNSET_VALUE
          @verbose             = UNSET_VALUE
          @version             = UNSET_VALUE
        end

        def finalize!
          @become              = false                    if @become              != true
          @become_user         = nil                      if @become_user         == UNSET_VALUE
          @compatibility_mode  = nil                      unless Ansible::COMPATIBILITY_MODES.include?(@compatibility_mode)
          @config_file         = nil                      if @config_file         == UNSET_VALUE
          @extra_vars          = nil                      if @extra_vars          == UNSET_VALUE
          @galaxy_role_file    = nil                      if @galaxy_role_file    == UNSET_VALUE
          @galaxy_roles_path   = nil                      if @galaxy_roles_path   == UNSET_VALUE
          @galaxy_command      = GALAXY_COMMAND_DEFAULT   if @galaxy_command      == UNSET_VALUE
          @groups              = {}                       if @groups              == UNSET_VALUE
          @host_vars           = {}                       if @host_vars           == UNSET_VALUE
          @inventory_path      = nil                      if @inventory_path      == UNSET_VALUE
          @limit               = nil                      if @limit               == UNSET_VALUE
          @playbook            = nil                      if @playbook            == UNSET_VALUE
          @playbook_command    = PLAYBOOK_COMMAND_DEFAULT if @playbook_command    == UNSET_VALUE
          @raw_arguments       = nil                      if @raw_arguments       == UNSET_VALUE
          @skip_tags           = nil                      if @skip_tags           == UNSET_VALUE
          @start_at_task       = nil                      if @start_at_task       == UNSET_VALUE
          @tags                = nil                      if @tags                == UNSET_VALUE
          @vault_password_file = nil                      if @vault_password_file == UNSET_VALUE
          @verbose             = false                    if @verbose             == UNSET_VALUE
          @version             = ""                       if @version             == UNSET_VALUE
        end

        # Just like the normal configuration "validate" method except that
        # it returns an array of errors that should be merged into some
        # other error accumulator.
        def validate(machine)
          @errors = _detected_errors

          # Validate that a compatibility mode was provided
          if !compatibility_mode
            @errors << I18n.t("vagrant.provisioners.ansible.errors.no_compatibility_mode",
              valid_modes: Ansible::COMPATIBILITY_MODES.map { |s| "'#{s}'" }.join(', '))
          end

          # Validate that a playbook path was provided
          if !playbook
            @errors << I18n.t("vagrant.provisioners.ansible.errors.no_playbook")
          end

          # Validate that extra_vars is either a Hash or a String (for a file path)
          if extra_vars
            extra_vars_is_valid = extra_vars.kind_of?(Hash) || extra_vars.kind_of?(String)
            if extra_vars.kind_of?(String)
              # Accept the usage of '@' prefix in Vagrantfile
              # (e.g. '@vars.yml' and 'vars.yml' are both supported)
              match_data = /^@?(.+)$/.match(extra_vars)
              extra_vars_path = match_data[1].to_s
              @extra_vars = '@' + extra_vars_path
            end

            if !extra_vars_is_valid
              @errors << I18n.t(
                "vagrant.provisioners.ansible.errors.extra_vars_invalid",
                type:  extra_vars.class.to_s,
                value: extra_vars.to_s)
            end
          end

          if raw_arguments
            if raw_arguments.kind_of?(String)
              @raw_arguments = [raw_arguments]
            elsif !raw_arguments.kind_of?(Array)
              @errors << I18n.t(
                "vagrant.provisioners.ansible.errors.raw_arguments_invalid",
                type:  raw_arguments.class.to_s,
                value: raw_arguments.to_s)
            end
          end

        end

        protected

        def show_deprecation_info(deprecated_option, new_option)
          puts "DEPRECATION: The '#{deprecated_option}' option for the Ansible provisioner is deprecated."
          puts "Please use the '#{new_option}' option instead."
          puts "The '#{deprecated_option}' option will be removed in a future release of Vagrant.\n\n"
        end
      end
    end
  end
end
