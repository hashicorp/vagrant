require_relative "base"

module VagrantPlugins
  module Ansible
    module Config
      class Host < Base

        attr_accessor :ask_become_pass
        attr_accessor :ask_vault_pass
        attr_accessor :force_remote_user
        attr_accessor :host_key_checking
        attr_accessor :raw_ssh_args

        #
        # Deprecated options
        #
        alias :ask_sudo_pass :ask_become_pass
        def ask_sudo_pass=(value)
          show_deprecation_info 'ask_sudo_pass', 'ask_become_pass'
          @ask_become_pass = value
        end

        def initialize
          super

          @ask_become_pass     = false
          @ask_vault_pass      = false
          @force_remote_user   = true
          @host_key_checking   = false
          @raw_ssh_args        = UNSET_VALUE
        end

        def finalize!
          super

          @ask_become_pass     = false if @ask_become_pass   != true
          @ask_vault_pass      = false if @ask_vault_pass    != true
          @force_remote_user   = true  if @force_remote_user != false
          @host_key_checking   = false if @host_key_checking != true
          @raw_ssh_args        = nil   if @raw_ssh_args      == UNSET_VALUE
        end

        def validate(machine)
          super

          if raw_ssh_args
            if raw_ssh_args.kind_of?(String)
              @raw_ssh_args = [raw_ssh_args]
            elsif !raw_ssh_args.kind_of?(Array)
              @errors << I18n.t(
                "vagrant.provisioners.ansible.errors.raw_ssh_args_invalid",
                type:  raw_ssh_args.class.to_s,
                value: raw_ssh_args.to_s)
            end
          end

          { "ansible remote provisioner" => @errors }
        end

      end
    end
  end
end
