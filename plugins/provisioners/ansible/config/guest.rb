require_relative "base"
require_relative "../helpers"

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

      end
    end
  end
end
