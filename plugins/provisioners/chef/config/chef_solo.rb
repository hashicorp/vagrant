require File.expand_path("../base", __FILE__)

module VagrantPlugins
  module Chef
    module Config
      class ChefSolo < Base
        attr_accessor :cookbooks_path
        attr_accessor :data_bags_path
        attr_accessor :environments_path
        attr_accessor :recipe_url
        attr_accessor :roles_path
        attr_accessor :synced_folder_type

        def initialize
          super

          @cookbooks_path            = UNSET_VALUE
          @data_bags_path            = UNSET_VALUE
          @environments_path         = UNSET_VALUE
          @recipe_url                = UNSET_VALUE
          @roles_path                = UNSET_VALUE
          @synced_folder_type        = UNSET_VALUE
        end

        def nfs=(value)
          puts "DEPRECATION: The 'nfs' setting for the Chef Solo provisioner is"
          puts "deprecated. Please use the 'synced_folder_type' setting instead."
          puts "The 'nfs' setting will be removed in the next version of Vagrant."

          if value
            @synced_folder_type = "nfs"
          else
            @synced_folder_type = nil
          end
        end

        #------------------------------------------------------------
        # Internal methods
        #------------------------------------------------------------

        def finalize!
          super

          @recipe_url = nil if @recipe_url == UNSET_VALUE
          @synced_folder_type = nil if @synced_folder_type == UNSET_VALUE

          if @cookbooks_path == UNSET_VALUE
            @cookbooks_path = []
            @cookbooks_path << [:host, "cookbooks"] if !@recipe_url
            @cookbooks_path << [:vm, "cookbooks"]
          end

          @data_bags_path    = [] if @data_bags_path == UNSET_VALUE
          @roles_path        = [] if @roles_path == UNSET_VALUE
          @environments_path = [] if @environments_path == UNSET_VALUE
          @environments_path = [@environments_path].flatten

          # Make sure the path is an array.
          @cookbooks_path    = prepare_folders_config(@cookbooks_path)
          @data_bags_path    = prepare_folders_config(@data_bags_path)
          @roles_path        = prepare_folders_config(@roles_path)
          @environments_path = prepare_folders_config(@environments_path)
        end

        def validate(machine)
          errors = _detected_errors
          errors.concat(validate_base(machine))
          errors << I18n.t("vagrant.config.chef.cookbooks_path_empty") if \
            !cookbooks_path || [cookbooks_path].flatten.empty?
          errors << I18n.t("vagrant.config.chef.environment_path_required") if \
            environment && environments_path.empty?

          environments_path.each do |type, raw_path|
            next if type != :host

            path = Pathname.new(raw_path).expand_path(machine.env.root_path)
            if !path.directory?
              errors << I18n.t("vagrant.config.chef.environment_path_missing",
                               path: raw_path.to_s)
            end
          end

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
