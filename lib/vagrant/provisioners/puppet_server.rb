module Vagrant
  module Provisioners
    class PuppetServerError < Vagrant::Errors::VagrantError
      error_namespace("vagrant.provisioners.puppet_server")
    end

    class PuppetServer < Base
      register :puppet_server

      class Config < Vagrant::Config::Base
        attr_accessor :puppet_server
        attr_accessor :puppet_node
        attr_accessor :options

        def initialize
          @puppet_server = "puppet"
          @puppet_node = "puppet_node"
          @options = []
        end
      end

      def provision!
        verify_binary("puppetd")
        run_puppetd_client
      end

      def verify_binary(binary)
        vm.ssh.execute do |ssh|
          ssh.sudo!("which #{binary}", :error_class => PuppetServerError, :_key => :puppetd_not_detected, :binary => binary)
        end
      end

      def run_puppetd_client
        options = config.options
        options = options.join(" ") if options.is_a?(Array)
        if config.puppet_node
          cn = config.puppet_node
        else
          cn = env.config.vm.box
        end

        commands = "puppetd #{options} --server #{config.puppet_server} --certname #{cn}"

        env.ui.info I18n.t("vagrant.provisioners.puppet_server.running_puppetd")

        vm.ssh.execute do |ssh|
          ssh.sudo!(commands) do |channel, type, data|
            ssh.check_exit_status(data, commands) if type == :exit_status
            env.ui.info(data) if type != :exit_status
          end
        end
      end
    end
  end
end
