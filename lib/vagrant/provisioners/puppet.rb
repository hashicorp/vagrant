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
        attr_accessor :pp_path
        attr_accessor :options

        def initialize
          @manifest_file = nil
          @manifests_path = "manifests"
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

        def validate(errors)
          super

          if !expanded_manifests_path.directory?
            errors.add(I18n.t("vagrant.provisioners.puppet.manifests_path_missing", :path => expanded_manifests_path))
            return
          end

          errors.add(I18n.t("vagrant.provisioners.puppet.manifest_missing", :manifest => computed_manifest_file)) if !expanded_manifests_path.join(computed_manifest_file).file?
        end
      end

      def prepare
        share_manifests
      end

      def provision!
        verify_binary("puppet")
        create_pp_path
        run_puppet_client
      end

      def share_manifests
        env.config.vm.share_folder("manifests", config.pp_path, config.manifests_path)
      end

      def verify_binary(binary)
        vm.ssh.execute do |ssh|
          ssh.exec!("sudo -i which #{binary}", :error_class => PuppetError, :_key => :puppet_not_detected, :binary => binary)
        end
      end

      def create_pp_path
        vm.ssh.execute do |ssh|
          ssh.exec!("sudo mkdir -p #{config.pp_path}")
          ssh.exec!("sudo chown #{env.config.ssh.username} #{config.pp_path}")
        end
      end

      def run_puppet_client
        options = [config.options].flatten
        options << config.computed_manifest_file
        options = options.join(" ")

        command = "sudo -i 'cd #{config.pp_path}; puppet #{options}'"

        env.ui.info I18n.t("vagrant.provisioners.puppet.running_puppet", :manifest => config.computed_manifest_file)

        vm.ssh.execute do |ssh|
          ssh.exec! command do |ch, type, data|
            if type == :exit_status
              ssh.check_exit_status(data, command)
            else
              env.ui.info(data)
            end
          end
        end
      end
    end
  end
end
