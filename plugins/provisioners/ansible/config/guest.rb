require_relative "base"
require_relative "../helpers"

module VagrantPlugins
  module Ansible
    module Config
      class Guest < Base

        attr_accessor :provisioning_path
        attr_accessor :tmp_path
        attr_accessor :install
        attr_accessor :install_mode
        attr_accessor :pip_args

        def initialize
          super

          @install           = UNSET_VALUE
          @install_mode      = UNSET_VALUE
          @pip_args          = UNSET_VALUE
          @provisioning_path = UNSET_VALUE
          @tmp_path          = UNSET_VALUE
        end

        def finalize!
          super

          @install           = true                   if @install           == UNSET_VALUE
          @install_mode      = :default               if @install_mode      == UNSET_VALUE
          @pip_args          = ""                     if @pip_args          == UNSET_VALUE
          @provisioning_path = "/vagrant"             if provisioning_path  == UNSET_VALUE
          @tmp_path          = "/tmp/vagrant-ansible" if tmp_path           == UNSET_VALUE
        end

        def validate(machine)
          super

          case @install_mode.to_s.to_sym
          when :pip
            @install_mode = :pip
          when :pip_args_only
            @install_mode = :pip_args_only
          else
            @install_mode = :default
          end

          { "ansible local provisioner" => @errors }
        end

      end
    end
  end
end
