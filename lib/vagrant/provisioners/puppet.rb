require "log4r"

module Vagrant
  module Provisioners
    class PuppetError < Vagrant::Errors::VagrantError
      error_namespace("vagrant.provisioners.puppet")
    end

    class Puppet < Base
      class Config < Vagrant::Config::Base
        attr_accessor :manifest_file
        attr_accessor :manifests_path
        attr_accessor :module_path
        attr_accessor :pp_path
        attr_accessor :options
        attr_accessor :facter

        def manifest_file; @manifest_file || "default.pp"; end
        def manifests_path; @manifests_path || "manifests"; end
        def pp_path; @pp_path || "/tmp/vagrant-puppet"; end
        def options; @options ||= []; end
        def facter; @facter ||= {}; end

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

        def validate(env, errors)
          # Calculate the manifests and module paths based on env
          this_expanded_manifests_path = expanded_manifests_path(env.root_path)
          this_expanded_module_paths = expanded_module_paths(env.root_path)

          # Manifests path/file validation
          if !this_expanded_manifests_path.directory?
            errors.add(I18n.t("vagrant.provisioners.puppet.manifests_path_missing",
                              :path => this_expanded_manifests_path))
          else
            expanded_manifest_file = this_expanded_manifests_path.join(manifest_file)
            if !expanded_manifest_file.file?
              errors.add(I18n.t("vagrant.provisioners.puppet.manifest_missing",
                                :manifest => expanded_manifest_file.to_s))
            end
          end

          # Module paths validation
          this_expanded_module_paths.each do |path|
            if !path.directory?
              errors.add(I18n.t("vagrant.provisioners.puppet.module_path_missing", :path => path))
            end
          end
        end
      end

      def self.config_class
        Config
      end

      def initialize(env, config)
        super

        @logger = Log4r::Logger.new("vagrant::provisioners::puppet")
      end

      def prepare
        # Calculate the paths we're going to use based on the environment
        @expanded_manifests_path = config.expanded_manifests_path(env[:root_path])
        @expanded_module_paths   = config.expanded_module_paths(env[:root_path])
        @manifest_file           = File.join(manifests_guest_path, config.manifest_file)

        set_module_paths
        share_manifests
        share_module_paths
      end

      def provision!
        # Check that the shared folders are properly shared
        check = [manifests_guest_path]
        @module_paths.each do |host_path, guest_path|
          check << guest_path
        end

        verify_shared_folders(check)

        # Verify Puppet is installed and run it
        verify_binary("puppet")
        run_puppet_client
      end

      def share_manifests
        env[:vm].config.vm.share_folder("manifests", manifests_guest_path, @expanded_manifests_path)
      end

      def share_module_paths
        count = 0
        @module_paths.each do |from, to|
          # Sorry for the cryptic key here, but VirtualBox has a strange limit on
          # maximum size for it and its something small (around 10)
          env[:vm].config.vm.share_folder("v-pp-m#{count}", to, from)
          count += 1
        end
      end

      def set_module_paths
        @module_paths = []
        @expanded_module_paths.each_with_index do |path, i|
          @module_paths << [path, File.join(config.pp_path, "modules-#{i}")]
        end
      end

      def manifests_guest_path
        File.join(config.pp_path, "manifests")
      end

      def verify_binary(binary)
        env[:vm].channel.sudo("which #{binary}",
                              :error_class => PuppetError,
                              :error_key => :not_detected,
                              :binary => binary)
      end

      def run_puppet_client
        options = [config.options].flatten
        module_paths = @module_paths.map { |_, to| to }
        options << "--modulepath '#{module_paths.join(':')}'" if !@module_paths.empty?
        options << @manifest_file
        options = options.join(" ")

        # Build up the custom facts if we have any
        facter = ""
        if !config.facter.empty?
          facts = []
          config.facter.each do |key, value|
            facts << "FACTER_#{key}='#{value}'"
          end

          facter = "#{facts.join(" ")} "
        end

        command = "cd #{manifests_guest_path} && #{facter}puppet apply #{options} --detailed-exitcodes || [ $? -eq 2 ]"

        env[:ui].info I18n.t("vagrant.provisioners.puppet.running_puppet",
                             :manifest => @manifest_file)

        env[:vm].channel.sudo(command) do |type, data|
          env[:ui].info(data.chomp, :prefix => false)
        end
      end

      def verify_shared_folders(folders)
        folders.each do |folder|
          @logger.debug("Checking for shared folder: #{folder}")
          if !env[:vm].channel.test("test -d #{folder}")
            raise PuppetError, :missing_shared_folders
          end
        end
      end
    end
  end
end

