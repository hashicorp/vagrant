module VagrantPlugins
  module Ansible
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :playbook
      attr_accessor :extra_vars
      attr_accessor :inventory_file
      attr_accessor :ask_sudo_pass
      attr_accessor :limit
      attr_accessor :sudo
      attr_accessor :sudo_user
      attr_accessor :verbose

      def initialize
        @playbook       = UNSET_VALUE
        @extra_vars     = UNSET_VALUE
        @inventory_file = UNSET_VALUE
        @ask_sudo_pass  = UNSET_VALUE
        @limit          = UNSET_VALUE
        @sudo           = UNSET_VALUE
        @sudo_user      = UNSET_VALUE
        @verbose        = UNSET_VALUE
      end

      def finalize!
        @playbook       = nil if @playbook == UNSET_VALUE
        @extra_vars     = nil if @extra_vars == UNSET_VALUE
        @inventory_file = nil if @inventory_file == UNSET_VALUE
        @ask_sudo_pass  = nil if @ask_sudo_pass == UNSET_VALUE
        @limit          = nil if @limit == UNSET_VALUE
        @sudo           = nil if @sudo == UNSET_VALUE
        @sudo_user      = nil if @sudo_user == UNSET_VALUE
        @verbose        = nil if @verbose == UNSET_VALUE
      end

      def validate(machine)
        errors = []
        
        if !playbook
          errors << I18n.t("vagrant.provisioners.ansible.no_playbook")
        end

        { "ansible provisioner" => errors }
      end
    end
  end
end
