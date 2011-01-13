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
          @manifest_file = ""
          @manifests_path = "manifests"
          @pp_path = "/tmp/vagrant-puppet"
          @options = []
        end
      end

      def prepare
        check_manifest_dir
        share_manifests
      end

      def provision!
        verify_binary("puppet")
        create_pp_path
        set_manifest
        run_puppet_client
      end

      def check_manifest_dir
        Dir.mkdir(config.manifests_path) unless File.directory?(config.manifests_path)
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

      def set_manifest
        @manifest = !config.manifest_file.empty? ? config.manifest_file : "#{env.config.vm.box}.pp"

        if File.exists?("#{config.manifests_path}/#{@manifest}")
          env.ui.info I18n.t("vagrant.provisioners.puppet.manifest_to_run", :manifest => @manifest)
          return @manifest
        else
          raise PuppetError, :_key => :manifest_missing, :manifest => @manifest
        end
      end

      def run_puppet_client
        options = [config.options].flatten
        options << @manifest
        options = options.join(" ")

        command = "sudo -i 'cd #{config.pp_path}; puppet #{options}'"

        env.ui.info I18n.t("vagrant.provisioners.puppet.running_puppet")

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
