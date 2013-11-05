require File.expand_path("../base", __FILE__)

require "vagrant/util/which"

module VagrantPlugins
  module Chef
    module Config
      class ChefClient < Base
        attr_accessor :chef_server_url
        attr_accessor :client_key_path
        attr_accessor :delete_client
        attr_accessor :delete_node
        attr_accessor :encrypted_data_bag_secret_key_path
        attr_accessor :encrypted_data_bag_secret
        attr_accessor :environment
        attr_accessor :validation_key_path
        attr_accessor :validation_client_name

        attr_accessor :local_mode
        attr_accessor :cookbooks_path
        attr_accessor :roles_path
        attr_accessor :data_bags_path
        attr_accessor :environments_path
        attr_accessor :nodes_path
        attr_accessor :clients_path


        def initialize
          super

          @chef_server_url                    = UNSET_VALUE
          @client_key_path                    = UNSET_VALUE
          @delete_client                      = UNSET_VALUE
          @delete_node                        = UNSET_VALUE
          @encrypted_data_bag_secret_key_path = UNSET_VALUE
          @encrypted_data_bag_secret          = UNSET_VALUE
          @environment                        = UNSET_VALUE
          @validation_key_path                = UNSET_VALUE
          @validation_client_name             = UNSET_VALUE


          @local_mode                         = UNSET_VALUE
          @cookbooks_path                     = UNSET_VALUE
          @roles_path                         = UNSET_VALUE
          @data_bags_path                     = UNSET_VALUE
          @environments_path                  = UNSET_VALUE
          @nodes_path                         = UNSET_VALUE
          @clients_path                       = UNSET_VALUE
        end

        def finalize!
          super

          @chef_server_url = nil if @chef_server_url == UNSET_VALUE
          @client_key_path        = "/etc/chef/client.pem" if @client_key_path == UNSET_VALUE
          @delete_client = false if @delete_client == UNSET_VALUE
          @delete_node = false if @delete_node == UNSET_VALUE
          @encrypted_data_bag_secret_key_path = nil if @encrypted_data_bag_secret_key_path == UNSET_VALUE
          @encrypted_data_bag_secret          = "/tmp/encrypted_data_bag_secret" if @encrypted_data_bag_secret == UNSET_VALUE
          @environment = nil if @environment == UNSET_VALUE
          @validation_client_name = "chef-validator" if @validation_client_name == UNSET_VALUE
          @validation_key_path = nil if @validation_key_path == UNSET_VALUE

          @local_mode = false if @local_mode == UNSET_VALUE

          #
          # Taken from chef_solo.rb
          #
          if @cookbooks_path == UNSET_VALUE
            @cookbooks_path = []
            @cookbooks_path << [:host, "cookbooks"] if !@recipe_url
            @cookbooks_path << [:vm, "cookbooks"]
          end

          @data_bags_path    = [] if @data_bags_path == UNSET_VALUE
          @roles_path        = [] if @roles_path == UNSET_VALUE
          @environments_path = [] if @environments_path == UNSET_VALUE
          @environments_path = [@environments_path].flatten
          @nodes_path        = [] if @nodes_path == UNSET_VALUE
          @clients_path      = [] if @clients_path == UNSET_VALUE

          # Make sure the path is an array.
          @cookbooks_path    = prepare_folders_config(@cookbooks_path)
          @data_bags_path    = prepare_folders_config(@data_bags_path)
          @roles_path        = prepare_folders_config(@roles_path)
          @environments_path = prepare_folders_config(@environments_path)
          @nodes_path        = prepare_folders_config(@nodes_path)
          @clients_path      = prepare_folders_config(@clients_path)
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

        protected

        # This takes any of the configurations that take a path or
        # array of paths and turns it into the proper format.
        #
        # @return [Array]
        def prepare_folders_config(config)
          # Make sure the path is an array
          config = [config] if !config.is_a?(Array) || config.first.is_a?(Symbol)

          # Make sure all the paths are in the proper format
          config.map do |path|
            path = [:host, path] if !path.is_a?(Array)
            path
          end
        end
      end
    end
  end
end
