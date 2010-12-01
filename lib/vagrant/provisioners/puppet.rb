module Vagrant
  module Provisioners

  class PuppetError < Vagrant::Errors::VagrantError
    error_namespace("vagrant.provisioners.puppet")
  end

  class PuppetConfig < Vagrant::Config::Base
    configures :puppet

    attr_accessor :manifest_file
    attr_accessor :manifests_path
    attr_accessor :pp_path

    def initialize
      @manifest_file = ""
      @manifests_path = "manifests"
      @pp_path = "/tmp/vagrant-puppet"
    end
  end

  class Puppet < Base

    def prepare
     share_manifests
    end

    def provision!
      verify_binary("puppet")
      create_pp_path
      run_puppet_client
    end

    def create_pp_path
      vm.ssh.execute do |ssh|
        ssh.exec!("sudo mkdir -p #{env.config.puppet.pp_path}")
        ssh.exec!("sudo chown #{env.config.ssh.username} #{env.config.puppet.pp_path}")
      end
    end

    def share_manifests
      env.config.vm.share_folder("manifests", env.config.puppet.pp_path, env.config.puppet.manifests_path)
    end

    def verify_binary(binary)
      vm.ssh.execute do |ssh|
      # Checks for the existence of Puppet binary and error if it
      # doesn't exist.
        ssh.exec!("which #{binary}", :error_class => PuppetError, :_key => :puppet_not_detected, :binary => binary)
      end
    end

    def run_puppet_client
      unless env.config.puppet.manifest_file
        env.config.puppet.manifest_file = "#{env.config.vm.box}.pp"
      end

      command = "cd #{env.config.puppet.pp_path} && sudo -E puppet #{env.config.puppet.manifest_file}"

      env.ui.info I18n.t("vagrant.provisioners.puppet.running_puppet")

      vm.ssh.execute do |ssh|
        ssh.exec!(command) do |channel, type, data|
          ssh.check_exit_status(data, command) if type == :exit_status
          env.ui.info("#{data}: #{type}") if type != :exit_status
        end
      end
    end
   end
 end
end
