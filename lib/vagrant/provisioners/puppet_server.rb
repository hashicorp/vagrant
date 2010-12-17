module Vagrant
  module Provisioners

  class PuppetServerError < Vagrant::Errors::VagrantError
    error_namespace("vagrant.provisioners.puppet_server")
  end

  class PuppetServerConfig < Vagrant::Config::Base
    configures :puppet_server

    attr_accessor :puppet_server
    attr_accessor :puppet_node
    attr_accessor :options

    def initialize
      @puppet_server = "puppet"
      @puppet_node = "puppet_node"
      @options = []
    end
  end

  class PuppetServer < Base

    def provision!
      verify_binary("puppetd")
      run_puppetd_client
    end

    def verify_binary(binary)
      vm.ssh.execute do |ssh|
      # Checks for the existence of puppetd binary and error if it
      # doesn't exist.
        ssh.exec!("which #{binary}", :error_class => PuppetServerError, :_key => :puppetd_not_detected, :binary => binary)
      end
    end

    def run_puppetd_client
     options = env.config.puppet_server.options
     options = options.join(" ") if options.is_a?(Array)
     if env.config.puppet_server.puppet_node
        cn = env.config.puppet_server.puppet_node
      else
        cn = env.config.vm.box
      end

      command = "sudo -E puppetd #{options} --server #{env.config.puppet_server.puppet_server} --certname #{cn}"

      env.ui.info I18n.t("vagrant.provisioners.puppet_server.running_puppetd")

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
