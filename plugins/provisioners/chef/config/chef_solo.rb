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

        def initialize
          super

          @cookbooks_path            = UNSET_VALUE
          @encrypted_data_bag_secret = UNSET_VALUE
          @nfs                       = UNSET_VALUE
        end

        def finalize!
          if @cookbooks_path == UNSET_VALUE
            @cookbooks_path = [[:host, "cookbooks"], [:vm, "cookbooks"]]
          end

          # Make sure all the paths are the proper format
          @cookbooks_path.map! do |path|
            path = [:host, path] if !path.is_a?(Array)
            path
          end

          @encrypted_data_bag_secret = "/tmp/encrypted_data_bag_secret" if \
            @encrypted_data_bag_secret == UNSET_VALUE
          @nfs = false if @nfs == UNSET_VALUE
        end

        def validate(machine)
          errors = []
          errors << I18n.t("vagrant.config.chef.cookbooks_path_empty") if \
            !cookbooks_path || [cookbooks_path].flatten.empty?
          errors << I18n.t("vagrant.config.chef.run_list_empty") if \
            !run_list || run_list.empty?

          @cookbooks_path.each do |type, path|
            next if type != :host
            expanded_path = File.expand_path(path, machine.env.root_path)

            if !File.exist?(expanded_path)
              errors << I18n.t("vagrant.config.chef.cookbooks_path_missing",
                              :path => expanded_path)
            end
          end

          { "chef solo provisioner" => errors }
        end
      end
    end
  end
end
