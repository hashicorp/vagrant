module VagrantPlugins
  module Ansible
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :playbook
      attr_accessor :extra_vars
      attr_accessor :inventory_path
      attr_accessor :ask_sudo_pass
      attr_accessor :limit
      attr_accessor :sudo
      attr_accessor :sudo_user
      attr_accessor :verbose
      attr_accessor :tags
      attr_accessor :skip_tags
      attr_accessor :start_at_task
      attr_accessor :host_key_checking

      # Joker attribute, used to pass unsupported arguments to ansible anyway
      attr_accessor :raw_arguments

      def initialize
        @playbook          = UNSET_VALUE
        @extra_vars        = UNSET_VALUE
        @inventory_path    = UNSET_VALUE
        @ask_sudo_pass     = UNSET_VALUE
        @limit             = UNSET_VALUE
        @sudo              = UNSET_VALUE
        @sudo_user         = UNSET_VALUE
        @verbose           = UNSET_VALUE
        @tags              = UNSET_VALUE
        @skip_tags         = UNSET_VALUE
        @start_at_task     = UNSET_VALUE
        @raw_arguments     = UNSET_VALUE
        @host_key_checking = "true"
      end

      def finalize!
        @playbook          = nil if @playbook == UNSET_VALUE
        @extra_vars        = nil if @extra_vars == UNSET_VALUE
        @inventory_path    = nil if @inventory_path == UNSET_VALUE
        @ask_sudo_pass     = nil if @ask_sudo_pass == UNSET_VALUE
        @limit             = nil if @limit == UNSET_VALUE
        @sudo              = nil if @sudo == UNSET_VALUE
        @sudo_user         = nil if @sudo_user == UNSET_VALUE
        @verbose           = nil if @verbose == UNSET_VALUE
        @tags              = nil if @tags == UNSET_VALUE
        @skip_tags         = nil if @skip_tags == UNSET_VALUE
        @start_at_task     = nil if @start_at_task == UNSET_VALUE
        @raw_arguments     = nil if @raw_arguments == UNSET_VALUE
        @host_key_checking = nil if @host_key_checking == UNSET_VALUE

        if @extra_vars && @extra_vars.is_a?(Hash)
          @extra_vars.each do |k, v|
            @extra_vars[k] = v.to_s
          end
        end
      end

      def validate(machine)
        errors = _detected_errors

        # Validate that a playbook path was provided
        if !playbook
          errors << I18n.t("vagrant.provisioners.ansible.no_playbook")
        end

        # Validate the existence of said playbook on the host
        if playbook
          expanded_path = Pathname.new(playbook).expand_path(machine.env.root_path)
          if !expanded_path.file?
            errors << I18n.t("vagrant.provisioners.ansible.playbook_path_invalid",
                              :path => expanded_path)
          end
        end

        # Validate that extra_vars is a hash, if set
        if extra_vars
          if !extra_vars.kind_of?(Hash)
            errors << I18n.t("vagrant.provisioners.ansible.extra_vars_not_hash")
          end
        end

        # Validate the existence of the inventory_path, if specified
        if inventory_path
          expanded_path = Pathname.new(inventory_path).expand_path(machine.env.root_path)
          if !expanded_path.exist?
            errors << I18n.t("vagrant.provisioners.ansible.inventory_path_invalid",
                              :path => expanded_path)
          end
        end

        { "ansible provisioner" => errors }
      end
    end
  end
end
