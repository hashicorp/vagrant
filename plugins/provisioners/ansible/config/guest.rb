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
          remote_path = File.expand_path(path, @provisioning_path)

          # Remove drive letter if running on a Windows host
          remote_path = remote_path.gsub(/^[a-zA-Z]:/, "")

          if machine.communicate.ready? && !machine.communicate.test("test #{test_args} #{remote_path}")
            if error_message_key
              @errors << I18n.t(error_message_key, path: remote_path, system: "guest")
            end
            return false
          end
          # when the machine is not ready for SSH communication,
          # the check is "optimistically" by passed.
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
