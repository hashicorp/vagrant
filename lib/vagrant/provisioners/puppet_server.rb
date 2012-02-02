module Vagrant
  module Provisioners
    class PuppetServerError < Vagrant::Errors::VagrantError
      error_namespace("vagrant.provisioners.puppet_server")
    end

    class PuppetServer < Base
      class Config < Vagrant::Config::Base
        attr_accessor :puppet_server
        attr_accessor :puppet_node
        attr_accessor :options

        def initialize
          @puppet_server = "puppet"
          @puppet_node = nil
          @options = []
        end
      end

      def self.config_class
        Config
      end

      def provision!
        verify_binary("puppetd")
        run_puppetd_client
      end

      def verify_binary(binary)
        env[:vm].channel.sudo("which #{binary}",
                              :error_class => PuppetServerError,
                              :error_key => :not_detected,
                              :binary => binary)
      end

      def run_puppetd_client
        options = config.options
        options = options.join(" ") if options.is_a?(Array)
        if config.puppet_node
          cn = "--certname #{config.puppet_node}"
        elsif env[:vm].config.vm.host_name
	  cn = ""
        else
          cn = "--certname #{env[:vm].config.vm.box}"
        end

        command = "puppetd #{options} --server #{config.puppet_server} #{cn}"

        env[:ui].info I18n.t("vagrant.provisioners.puppet_server.running_puppetd" + command)
        env[:vm].channel.sudo(command) do |type, data|
          env[:ui].info(data.chomp, :prefix => false)
        end
      end
    end
  end
end
