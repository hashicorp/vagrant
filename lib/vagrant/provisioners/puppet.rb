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
    attr_accessor :options

    def initialize
      @manifest_file = ""
      @manifests_path = "manifests"
      @pp_path = "/tmp/vagrant-puppet"
      @options = []
    end
  end

  class Puppet < Base

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
      Dir.mkdir(env.config.puppet.manifests_path) unless File.directory?(env.config.puppet.manifests_path)
    end

    def share_manifests
      env.config.vm.share_folder("manifests", env.config.puppet.pp_path, env.config.puppet.manifests_path)
    end

    def verify_binary(binary)
      vm.ssh.execute do |ssh|
        ssh.exec!("which #{binary}", :error_class => PuppetError, :_key => :puppet_not_detected, :binary => binary)
      end
    end

    def create_pp_path
      vm.ssh.execute do |ssh|
        ssh.exec!("sudo mkdir -p #{env.config.puppet.pp_path}")
        ssh.exec!("sudo chown #{env.config.ssh.username} #{env.config.puppet.pp_path}")
      end
    end

    def set_manifest
      @manifest = !env.config.puppet.manifest_file.empty? ? env.config.puppet.manifest_file : "#{env.config.vm.box}.pp"

      if File.exists?("#{env.config.puppet.manifests_path}/#{@manifest}")
         env.ui.info I18n.t("vagrant.provisioners.puppet.manifest_to_run", :manifest => @manifest)
         return @manifest
       else
         raise PuppetError.new(:_key => :manifest_missing, :manifest => @manifest)
      end 
    end 

    def run_puppet_client
      command = "cd #{env.config.puppet.pp_path} && sudo -E puppet #{env.config.puppet.options.join(" ")} #{@manifest}"

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
