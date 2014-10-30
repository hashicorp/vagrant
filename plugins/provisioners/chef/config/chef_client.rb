require "vagrant/util/which"

require_relative "base"

module VagrantPlugins
  module Chef
    module Config
      class ChefClient < Base
        attr_accessor :chef_server_url
        attr_accessor :client_key_path
        attr_accessor :delete_client
        attr_accessor :delete_node
        attr_accessor :validation_key_path
        attr_accessor :validation_client_name

        def initialize
          super

          @chef_server_url                    = UNSET_VALUE
          @client_key_path                    = UNSET_VALUE
          @delete_client                      = UNSET_VALUE
          @delete_node                        = UNSET_VALUE
          @validation_key_path                = UNSET_VALUE
          @validation_client_name             = UNSET_VALUE
        end

        def finalize!
          super

          @chef_server_url = nil if @chef_server_url == UNSET_VALUE
          @client_key_path        = "/etc/chef/client.pem" if @client_key_path == UNSET_VALUE
          @delete_client = false if @delete_client == UNSET_VALUE
          @delete_node = false if @delete_node == UNSET_VALUE
          @validation_client_name = "chef-validator" if @validation_client_name == UNSET_VALUE
          @validation_key_path = nil if @validation_key_path == UNSET_VALUE
        end

        def validate(machine)
          errors = _detected_errors
          errors.concat(validate_base(machine))
          errors << I18n.t("vagrant.config.chef.server_url_empty") if \
            !chef_server_url || chef_server_url.strip == ""
          errors << I18n.t("vagrant.config.chef.validation_key_path") if \
            !validation_key_path

          if delete_client || delete_node
            if !Vagrant::Util::Which.which("knife")
              errors << I18n.t("vagrant.chef_config_knife_not_found")
            end
          end

          { "chef client provisioner" => errors }
        end
      end
    end
  end
end
