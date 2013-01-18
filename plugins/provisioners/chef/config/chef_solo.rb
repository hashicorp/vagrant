require File.expand_path("../base", __FILE__)

module VagrantPlugins
  module Chef
    module Config
      class ChefSolo < Base
        attr_accessor :cookbooks_path
        attr_accessor :roles_path
        attr_accessor :data_bags_path
        attr_accessor :recipe_url
        attr_accessor :nfs
        attr_accessor :encrypted_data_bag_secret_key_path
        attr_accessor :encrypted_data_bag_secret

        def encrypted_data_bag_secret; @encrypted_data_bag_secret || "/tmp/encrypted_data_bag_secret"; end

        def initialize
          super

          @__default = ["cookbooks", [:vm, "cookbooks"]]
        end

        # Provide defaults in such a way that they won't override the instance
        # variable. This is so merging continues to work properly.
        def cookbooks_path
          @cookbooks_path || _default_cookbook_path
        end

        # This stores a reference to the default cookbook path which is used
        # later. Do not use this publicly. I apologize for not making it
        # "protected" but it has to be called by Vagrant internals later.
        def _default_cookbook_path
          @__default
        end

        def nfs
          @nfs || false
        end

        def validate(machine)
          errors = []
          errors << I18n.t("vagrant.config.chef.cookbooks_path_empty") if \
            !cookbooks_path || [cookbooks_path].flatten.empty?
          errors << I18n.t("vagrant.config.chef.run_list_empty") if \
            !run_list || run_list.empty?

          { "chef solo provisioner" => errors }
        end
      end
    end
  end
end
