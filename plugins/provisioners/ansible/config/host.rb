require_relative "base"

module VagrantPlugins
  module Ansible
    module Config
      class Host < Base

        attr_accessor :ask_sudo_pass
        attr_accessor :ask_vault_pass
        attr_accessor :host_key_checking
        attr_accessor :raw_ssh_args

        def initialize
          super

          @ask_sudo_pass       = false
          @ask_vault_pass      = false
          @host_key_checking   = false
          @raw_ssh_args        = UNSET_VALUE
        end

        def finalize!
          super

          @ask_sudo_pass       = false if @ask_sudo_pass     != true
          @ask_vault_pass      = false if @ask_vault_pass    != true
          @host_key_checking   = false if @host_key_checking != true
          @raw_ssh_args        = nil   if @raw_ssh_args      == UNSET_VALUE
        end

        def validate(machine)
          super

          { "ansible remote provisioner" => @errors }
        end

        protected

        def check_path(machine, path, path_test_method, error_message_key = nil)
          expanded_path = Pathname.new(path).expand_path(machine.env.root_path)
          if !expanded_path.public_send(path_test_method)
            if error_message_key
              @errors << I18n.t(error_message_key, path: expanded_path, system: "host")
            end
            return false
          end
          true
        end

        def check_path_is_a_file(machine, path, error_message_key = nil)
          check_path(machine, path, "file?", error_message_key)
        end

        def check_path_exists(machine, path, error_message_key = nil)
          check_path(machine, path, "exist?", error_message_key)
        end

      end
    end
  end
end
