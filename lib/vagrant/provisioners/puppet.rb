module Vagrant
  module Provisioners
    class PuppetError < Vagrant::Errors::VagrantError
      error_namespace("vagrant.provisioners.puppet")
    end

    class Puppet < Base
      register :puppet

      class Config < Vagrant::Config::Base
        attr_accessor :manifest_file
        attr_accessor :manifests_path
        attr_accessor :module_path
        attr_accessor :pp_path
        attr_accessor :options

        def initialize
          @manifest_file = nil
          @manifests_path = "manifests"
          @module_path = nil
          @pp_path = "/tmp/vagrant-puppet"
          @options = []
        end

        # Returns the manifests path expanded relative to the root path of the
        # environment.
        def expanded_manifests_path
          Pathname.new(manifests_path).expand_path(env.root_path)
        end

        # Returns the manifest file if set otherwise returns the box name pp file
        # which may or may not exist.
        def computed_manifest_file
          manifest_file || "#{top.vm.box}.pp"
        end

        # Returns the module paths as an array of paths expanded relative to the
        # root path.
        def expanded_module_paths
          return [] if !module_path

          # Get all the paths and expand them relative to the root path, returning
          # the array of expanded paths
          paths = module_path
          paths = [paths] if !paths.is_a?(Array)
          paths.map do |path|
            Pathname.new(path).expand_path(env.root_path)
          end
        end

        def validate(errors)
          super

          # Manifests path/file validation
          if !expanded_manifests_path.directory?
            errors.add(I18n.t("vagrant.provisioners.puppet.manifests_path_missing", :path => expanded_manifests_path))
          else
            if !expanded_manifests_path.join(computed_manifest_file).file?
              errors.add(I18n.t("vagrant.provisioners.puppet.manifest_missing", :manifest => computed_manifest_file))
            end
          end

          # Module paths validation
          expanded_module_paths.each do |path|
            if !path.directory?
              errors.add(I18n.t("vagrant.provisioners.puppet.module_path_missing", :path => path))
            end
          end
        end
      end

      def prepare
        set_module_paths
        share_manifests
        share_module_paths
      end

      def provision!
        verify_binary("puppet")
        run_puppet_client
      end

      def share_manifests
        env.config.vm.share_folder("manifests", manifests_guest_path, config.expanded_manifests_path)
      end

      def share_module_paths
        count = 0
        @module_paths.each do |from, to|
          # Sorry for the cryptic key here, but VirtualBox has a strange limit on
          # maximum size for it and its something small (around 10)
          env.config.vm.share_folder("v-pp-m#{count}", to, from)
          count += 1
        end
      end

      def set_module_paths
        @module_paths = {}
        config.expanded_module_paths.each_with_index do |path, i|
          @module_paths[path] = File.join(config.pp_path, "modules-#{i}")
        end
      end

      def manifests_guest_path
        File.join(config.pp_path, "manifests")
      end

      def verify_binary(binary)
        vm.ssh.execute do |ssh|
          ssh.sudo!("which #{binary}", :error_class => PuppetError, :_key => :puppet_not_detected, :binary => binary)
        end
      end

      def run_puppet_client
        options = [config.options].flatten
        options << "--modulepath '#{@module_paths.values.join(':')}'" if !@module_paths.empty?
        options << config.computed_manifest_file
        options = options.join(" ")

        commands = ["cd #{manifests_guest_path}",
                    "puppet #{options}"]

        env.ui.info I18n.t("vagrant.provisioners.puppet.running_puppet", :manifest => config.computed_manifest_file)

        vm.ssh.execute do |ssh|
          ssh.sudo! commands do |ch, type, data|
            if type == :exit_status
              ssh.check_exit_status(data, commands)
            else
              env.ui.info(data)
            end
          end
        end
      end
    end
  end
end
