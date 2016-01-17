require_relative "base"

module VagrantPlugins
  module Ansible
    module Config
      class Guest < Base

        attr_accessor :provisioning_path
        attr_accessor :tmp_path
        attr_accessor :install
        attr_accessor :version

        def initialize
          super

          @install           = UNSET_VALUE
          @provisioning_path = UNSET_VALUE
          @tmp_path          = UNSET_VALUE
          @version           = UNSET_VALUE
        end

        def finalize!
          super

          @install           = true                   if @install           == UNSET_VALUE
          @provisioning_path = "/vagrant"             if provisioning_path  == UNSET_VALUE
          @tmp_path          = "/tmp/vagrant-ansible" if tmp_path           == UNSET_VALUE
          @version           = ""                     if @version           == UNSET_VALUE
        end

        def validate(machine)
          super

          { "ansible local provisioner" => @errors }
        end

        protected

        def check_path(machine, path, test_args, error_message_key = nil)
          remote_path = Helpers::expand_path_in_unix_style(path, @provisioning_path)

          if machine.communicate.ready? && !machine.communicate.test("test #{test_args} #{remote_path}")
            if error_message_key
              # only show warnings, as raising an error would abort the request
              # vagrant action (e.g. prevent `destroy` to be executed)
              machine.ui.warn(I18n.t(error_message_key, path: remote_path, system: "guest"))
            end
            return false
          end
          # when the machine is not ready for SSH communication,
          # the check is "optimistically" bypassed.
          true
        end

        def check_path_is_a_file(machine, path, error_message_key = nil)
          check_path(machine, path, "-f", error_message_key)
        end

        def check_path_exists(machine, path, error_message_key = nil)
          check_path(machine, path, "-e", error_message_key)
        end

      end
    end
  end
end
