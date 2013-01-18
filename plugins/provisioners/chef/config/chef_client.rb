require File.expand_path("../base", __FILE__)

module VagrantPlugins
  module Chef
    module Config
      class ChefClient < Base
        attr_accessor :chef_server_url
        attr_accessor :validation_key_path
        attr_accessor :validation_client_name
        attr_accessor :client_key_path
        attr_accessor :file_cache_path
        attr_accessor :file_backup_path
        attr_accessor :environment
        attr_accessor :encrypted_data_bag_secret_key_path
        attr_accessor :encrypted_data_bag_secret

        # Provide defaults in such a way that they won't override the instance
        # variable. This is so merging continues to work properly.
        def validation_client_name; @validation_client_name || "chef-validator"; end
        def client_key_path; @client_key_path || "/etc/chef/client.pem"; end
        def file_cache_path; @file_cache_path || "/srv/chef/file_store"; end
        def file_backup_path; @file_backup_path || "/srv/chef/cache"; end
        def encrypted_data_bag_secret; @encrypted_data_bag_secret || "/tmp/encrypted_data_bag_secret"; end

        def validate(machine)
          errors = []
          errors << I18n.t("vagrant.config.chef.server_url_empty") if \
            !chef_server_url || chef_server_url.strip == ""
          errors << I18n.t("vagrant.config.chef.validation_key_path") if \
            !validation_key_path
          errors << I18n.t("vagrant.config.chef.run_list_empty") if \
            @run_list && @run_list.empty?

          { "chef client provisioner" => errors }
        end
      end
    end
  end
end
