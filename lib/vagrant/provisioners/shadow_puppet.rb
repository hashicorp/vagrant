module Vagrant
  module Provisioners
    class ShadowPuppetError < Vagrant::Errors::VagrantError
      error_namespace("vagrant.provisioners.shadow_puppet")
    end

    class ShadowPuppet < Base
      register :shadow_puppet

      class Config < Vagrant::Config::Base
        attr_accessor :manifest_file
        attr_accessor :manifests_path
        attr_accessor :remote_path
        attr_accessor :options

        def initialize
          @manifest_file = nil
          @manifests_path = "manifests"
          @remote_path = "/tmp/vagrant-shadow_puppet"
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
          manifest_file || "#{top.vm.box}_manifest.rb"
        end
        def validate(errors)
          super

          # Manifests path/file validation
          if !expanded_manifests_path.directory?
            errors.add(I18n.t("vagrant.provisioners.shadow_puppet.manifests_path_missing", :path => expanded_manifests_path))
          else
            if !expanded_manifests_path.join(computed_manifest_file).file?
              errors.add(I18n.t("vagrant.provisioners.shadow_puppet.manifest_missing", :manifest => computed_manifest_file))
            end
          end

        end
      end

      def prepare
        share_manifests
      end

      def provision!
        verify_binary("shadow_puppet")
        run_shadow_puppet_client
      end

      def share_manifests
        env.config.vm.share_folder("manifests", manifests_guest_path, config.expanded_manifests_path)
      end

      def manifests_guest_path
        File.join(config.remote_path, config.manifests_path)
      end

      def verify_binary(binary)
        vm.ssh.execute do |ssh|
          ssh.sudo!("which #{binary}", :error_class => ShadowPuppetError, :_key => :shadow_puppet_not_detected, :binary => binary)
        end
      end

      def run_shadow_puppet_client
        options = [config.options].flatten
        options << config.computed_manifest_file
        options = options.join(" ")

        commands = ["cd #{manifests_guest_path}",
                    "shadow_puppet #{options}"]

        env.ui.info I18n.t("vagrant.provisioners.shadow_puppet.running_shadow_puppet", :manifest => config.computed_manifest_file)

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