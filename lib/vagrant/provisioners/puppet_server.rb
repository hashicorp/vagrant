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
          @puppet_node = "puppet_node"
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
                              :error_key => :puppetd_not_detected,
                              :binary => binary)
      end

      def run_puppetd_client
        options = config.options
        options = options.join(" ") if options.is_a?(Array)
        if config.puppet_node
          cn = config.puppet_node
        else
          cn = env[:vm].config.vm.box
        end

        command = "puppetd #{options} --server #{config.puppet_server} --certname #{cn}"

        env[:ui].info I18n.t("vagrant.provisioners.puppet_server.running_puppetd")
        env[:vm].channel.sudo(command) do |type, data|
          # Output the data with the proper color based on the stream.
          color = type == :stdout ? :green : :red

          # Note: Be sure to chomp the data to avoid the newlines that the
          # Chef outputs.
          env[:ui].info(data.chomp, :color => color, :prefix => false)
        end
      end
    end
  end
end
