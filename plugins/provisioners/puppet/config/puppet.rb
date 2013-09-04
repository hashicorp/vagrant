module VagrantPlugins
  module Puppet
    module Config
      class Puppet < Vagrant.plugin("2", :config)
        attr_accessor :facter
        attr_accessor :hiera_config_path
        attr_accessor :manifest_file
        attr_accessor :manifests_path
        attr_accessor :module_path
        attr_accessor :options
        attr_accessor :temp_dir
        attr_accessor :working_directory
        attr_accessor :nfs

        def initialize
          super

          @hiera_config_path = UNSET_VALUE
          @manifest_file     = UNSET_VALUE
          @manifests_path    = UNSET_VALUE
          @module_path       = UNSET_VALUE
          @options           = []
          @facter            = {}
          @temp_dir          = UNSET_VALUE
          @working_directory = UNSET_VALUE
          @nfs               = UNSET_VALUE
        end

        def finalize!
          super

          @hiera_config_path = nil if @hiera_config_path == UNSET_VALUE
          @manifest_file  = "default.pp" if @manifest_file == UNSET_VALUE
          @manifests_path = "manifests" if @manifests_path == UNSET_VALUE
          @module_path    = nil if @module_path == UNSET_VALUE
          @temp_dir       = "/tmp/vagrant-puppet" if @temp_dir == UNSET_VALUE
          @working_directory = nil if @working_directory == UNSET_VALUE
          @nfs            = false if @nfs == UNSET_VALUE
        end

        # Returns the manifests path expanded relative to the root path of the
        # environment.
        def expanded_manifests_path(root_path)
          Pathname.new(manifests_path).expand_path(root_path)
        end

        # Returns the module paths as an array of paths expanded relative to the
        # root path.
        def expanded_module_paths(root_path)
          return [] if !module_path

          # Get all the paths and expand them relative to the root path, returning
          # the array of expanded paths
          paths = module_path
          paths = [paths] if !paths.is_a?(Array)
          paths.map do |path|
            Pathname.new(path).expand_path(root_path)
          end
        end

        def validate(machine)
          errors = _detected_errors

          # Calculate the manifests and module paths based on env
          this_expanded_manifests_path = expanded_manifests_path(machine.env.root_path)
          this_expanded_module_paths = expanded_module_paths(machine.env.root_path)

          # Manifests path/file validation
          if !this_expanded_manifests_path.directory?
            errors << I18n.t("vagrant.provisioners.puppet.manifests_path_missing",
                             :path => this_expanded_manifests_path)
          else
            expanded_manifest_file = this_expanded_manifests_path.join(manifest_file)
            if !expanded_manifest_file.file?
              errors << I18n.t("vagrant.provisioners.puppet.manifest_missing",
                               :manifest => expanded_manifest_file.to_s)
            end
          end

          # Module paths validation
          this_expanded_module_paths.each do |path|
            if !path.directory?
              errors << I18n.t("vagrant.provisioners.puppet.module_path_missing",
                               :path => path)
            end
          end

          { "puppet provisioner" => errors }
        end
      end
    end
  end
end
