require_relative "exception_logger"

module VagrantPlugins
  module CommandServe
    module Service
      class HostService < Hashicorp::Vagrant::Sdk::HostService::Service
        prepend VagrantPlugins::CommandServe::Service::ExceptionLogger

        [:detect].each do |method|
          VagrantPlugins::CommandServe::Service::ExceptionLogger.log_exception method
        end

        def detect_spec(*args)
          Hashicorp::Vagrant::Sdk::FuncSpec.new
        end

        def detect(*args)
          plugin_name = args.last.metadata["plugin_name"]
          plugin = Vagrant::Plugin::V2::Plugin.manager.hosts[plugin_name.to_sym].to_a.first
          if !plugin
            raise "Failed to locate host plugin for: #{plugin_name}"
          end
          Hashicorp::Vagrant::Sdk::Host::DetectResp.new(
            detected: plugin.new.detect?({})
          )
        end
      end
    end
  end
end
