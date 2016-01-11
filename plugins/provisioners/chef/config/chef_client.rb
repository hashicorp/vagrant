require "vagrant/util/presence"
require "vagrant/util/which"

require_relative "base_runner"

module VagrantPlugins
  module Chef
    module Config
      class ChefClient < BaseRunner
        include Vagrant::Util::Presence

        # The URL endpoint to the Chef Server.
        # @return [String]
        attr_accessor :chef_server_url

        # The path on disk to the Chef client key,
        # @return [String]
        attr_accessor :client_key_path

        # Delete the client key when the VM is destroyed. Default is false.
        # @return [true, false]
        attr_accessor :delete_client

        # Delete the node when the VM is destroyed. Default is false.
        # @return [true, false]
        attr_accessor :delete_node

        # The path to the validation key on disk.
        # @return [String]
        attr_accessor :validation_key_path

        # The name of the validation client.
        # @return [String]
        attr_accessor :validation_client_name

        def initialize
          super

          @chef_server_url        = UNSET_VALUE
          @client_key_path        = UNSET_VALUE
          @delete_client          = UNSET_VALUE
          @delete_node            = UNSET_VALUE
          @validation_key_path    = UNSET_VALUE
          @validation_client_name = UNSET_VALUE
        end

        def finalize!
          super

          @chef_server_url        = nil if @chef_server_url == UNSET_VALUE
          @client_key_path        = nil if @client_key_path == UNSET_VALUE
          @delete_client          = false if @delete_client == UNSET_VALUE
          @delete_node            = false if @delete_node == UNSET_VALUE
          @validation_client_name = "chef-validator" if @validation_client_name == UNSET_VALUE
          @validation_key_path    = nil if @validation_key_path == UNSET_VALUE
        end

        def validate(machine)
          errors = validate_base(machine)

          if !present?(chef_server_url)
            errors << I18n.t("vagrant.config.chef.server_url_empty")
          end

          if !present?(validation_key_path)
            errors << I18n.t("vagrant.config.chef.validation_key_path")
          end

          { "chef client provisioner" => errors }
        end
      end
    end
  end
end
