require "vagrant/util/presence"

require_relative "chef_solo"

module VagrantPlugins
  module Chef
    module Config
      class ChefZero < BaseRunner
        include Vagrant::Util::Presence

        # The path on disk where Chef cookbooks are stored.
        # Default is "cookbooks".
        # @return [String]
        attr_accessor :cookbooks_path

        # The path where data bags are stored on disk.
        # @return [String]
        attr_accessor :data_bags_path

        # The path where environments are stored on disk.
        # @return [String]
        attr_accessor :environments_path

        # The path where nodes are stored on disk.
        # @return [String]
        attr_accessor :nodes_path

        # The path where roles are stored on disk.
        # @return [String]
        attr_accessor :roles_path

        # The type of synced folders to use.
        # @return [String]
        attr_accessor :synced_folder_type

        def initialize
          super

          @cookbooks_path      = UNSET_VALUE
          @data_bags_path      = UNSET_VALUE
          @environments_path   = UNSET_VALUE
          @nodes_path          = UNSET_VALUE
          @roles_path          = UNSET_VALUE
          @synced_folder_type  = UNSET_VALUE
        end

        def finalize!
          super

          @synced_folder_type = nil if @synced_folder_type == UNSET_VALUE

          if @cookbooks_path == UNSET_VALUE
            @cookbooks_path = []
            @cookbooks_path << [:host, "cookbooks"] if !@recipe_url
            @cookbooks_path << [:vm, "cookbooks"]
          end

          @data_bags_path    = [] if @data_bags_path == UNSET_VALUE
          @nodes_path        = [] if @nodes_path == UNSET_VALUE
          @roles_path        = [] if @roles_path == UNSET_VALUE
          @environments_path = [] if @environments_path == UNSET_VALUE
          @environments_path = [@environments_path].flatten

          # Make sure the path is an array.
          @cookbooks_path    = prepare_folders_config(@cookbooks_path)
          @data_bags_path    = prepare_folders_config(@data_bags_path)
          @nodes_path        = prepare_folders_config(@nodes_path)
          @roles_path        = prepare_folders_config(@roles_path)
          @environments_path = prepare_folders_config(@environments_path)

        end

        def validate(machine)
          errors = validate_base(machine)

          if !present?(Array(cookbooks_path))
            errors << I18n.t("vagrant.config.chef.cookbooks_path_empty")
          end

          if !present?(Array(nodes_path))
            errors << I18n.t("vagrant.config.chef.nodes_path_empty")
          else
            missing_paths = Array.new
            nodes_path.each { |dir| missing_paths << dir[1] if !File.exists? dir[1] }
            # If it exists at least one path on disk it's ok for Chef provisioning
            if missing_paths.size == nodes_path.size
              errors << I18n.t("vagrant.config.chef.nodes_path_missing", path: missing_paths.to_s)
            end
          end

          if environment && environments_path.empty?
            errors << I18n.t("vagrant.config.chef.environment_path_required")
          end

          environments_path.each do |type, raw_path|
            next if type != :host

            path = Pathname.new(raw_path).expand_path(machine.env.root_path)
            if !path.directory?
              errors << I18n.t("vagrant.config.chef.environment_path_missing",
                path: raw_path.to_s
              )
            end
          end

          { "chef zero provisioner" => errors }
        end

        protected

        # This takes any of the configurations that take a path or
        # array of paths and turns it into the proper format.
        #
        # @return [Array]
        def prepare_folders_config(config)
          # Make sure the path is an array
          config = [config] if !config.is_a?(Array) || config.first.is_a?(Symbol)

          return [] if config.flatten.compact.empty?

          # Make sure all the paths are in the proper format
          config.map do |path|
            path = [:host, File.expand_path(path)] if !path.is_a?(Array)
            path
          end
        end
      end
    end
  end
end
