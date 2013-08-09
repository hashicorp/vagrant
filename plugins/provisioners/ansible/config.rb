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

      def initialize
        @playbook       = UNSET_VALUE
        @extra_vars     = UNSET_VALUE
        @inventory_path = UNSET_VALUE
        @ask_sudo_pass  = UNSET_VALUE
        @limit          = UNSET_VALUE
        @sudo           = UNSET_VALUE
        @sudo_user      = UNSET_VALUE
        @verbose        = UNSET_VALUE
      end

      def finalize!
        @playbook       = nil if @playbook == UNSET_VALUE
        @extra_vars     = nil if @extra_vars == UNSET_VALUE
        @inventory_path = nil if @inventory_path == UNSET_VALUE
        @ask_sudo_pass  = nil if @ask_sudo_pass == UNSET_VALUE
        @limit          = nil if @limit == UNSET_VALUE
        @sudo           = nil if @sudo == UNSET_VALUE
        @sudo_user      = nil if @sudo_user == UNSET_VALUE
        @verbose        = nil if @verbose == UNSET_VALUE
      end

      def validate(machine)
        errors = []

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
