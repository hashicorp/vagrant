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
          @data_bags_path            = UNSET_VALUE
          @recipe_url                = UNSET_VALUE
          @roles_path                = UNSET_VALUE
          @nfs                       = UNSET_VALUE
          @encrypted_data_bag_secret = UNSET_VALUE
          @encrypted_data_bag_secret_key_path = UNSET_VALUE

          @__defaulted_cookbooks_path = false
        end

        #------------------------------------------------------------
        # Internal methods
        #------------------------------------------------------------

        def finalize!
          super

          @recipe_url = nil if @recipe_url == UNSET_VALUE

          if @cookbooks_path == UNSET_VALUE
            @cookbooks_path = []
            @cookbooks_path << [:host, "cookbooks"] if !@recipe_url
            @cookbooks_path << [:vm, "cookbooks"]
            @__defaulted_cookbooks_path = true
          end

          @data_bags_path = [] if @data_bags_path == UNSET_VALUE
          @roles_path     = [] if @roles_path == UNSET_VALUE

          # Make sure the path is an array.
          @cookbooks_path = prepare_folders_config(@cookbooks_path)
          @data_bags_path = prepare_folders_config(@data_bags_path)
          @roles_path     = prepare_folders_config(@roles_path)

          @nfs = false if @nfs == UNSET_VALUE
          @encrypted_data_bag_secret = "/tmp/encrypted_data_bag_secret" if \
            @encrypted_data_bag_secret == UNSET_VALUE
          @encrypted_data_bag_secret_key_path = nil if \
            @encrypted_data_bag_secret_key_path == UNSET_VALUE
        end

        def validate(machine)
          errors = _detected_errors
          errors.concat(validate_base(machine))
          errors << I18n.t("vagrant.config.chef.cookbooks_path_empty") if \
            !cookbooks_path || [cookbooks_path].flatten.empty?

          { "chef solo provisioner" => errors }
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
