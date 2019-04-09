require "vagrant/go_plugin/core"

module Vagrant
  module GoPlugin
    # Contains all capability functionality for go-plugin
    module CapabilityPlugin
      extend Vagrant::Util::Logger

      # Wrapper class for go-plugin defined capabilities
      class Capability
        include GRPCPlugin
      end

      # Fetch any defined guest capabilites for given plugin and register
      # capabilities within given plugin class
      #
      # @param [Vagrant::Proto::GuestCapabilities::Stub] client Plugin client
      # @param [Class] plugin_klass Plugin class to register capabilities
      # @param [Symbol] plugin_type Type of plugin
      def self.generate_guest_capabilities(client, plugin_klass, plugin_type)
        logger.debug("checking for guest capabilities in #{plugin_type} plugin #{plugin_klass}")
        result = client.guest_capabilities(Vagrant::Proto::Empty.new)
        return if result.capabilities.empty?
        logger.debug("guest capabilities support detected in #{plugin_type} plugin #{plugin_klass}")
        result.capabilities.each do |cap|
          cap_klass = Class.new(Capability).tap do |k|
            k.class_eval("def self.#{cap.name}(machine, *args){ plugin_client.guest_capability(" \
              "Vagrant::Proto::GuestCapabilityRequest.new(" \
              "machine: JSON.dump(machine), arguments: JSON.dump(args)," \
              "capability: Vagrant::Proto::SystemCapability.new(" \
              "name: '#{cap.name}', platform: '#{cap.platform}'))) }")
          end
          cap_klass.plugin_client = client
          plugin_klass.guest_capability(cap.platform, cap.name) { cap_klass }
        end
      end

      # Fetch any defined host capabilites for given plugin and register
      # capabilities within given plugin class
      #
      # @param [Vagrant::Proto::HostCapabilities::Stub] client Plugin client
      # @param [Class] plugin_klass Plugin class to register capabilities
      # @param [Symbol] plugin_type Type of plugin
      def self.generate_host_capabilities(client, plugin_klass, plugin_type)
        logger.debug("checking for host capabilities in #{plugin_type} plugin #{plugin_klass}")
        result = client.host_capabilities(Vagrant::Proto::Empty.new)
        return if result.capabilities.empty?
        logger.debug("host capabilities support detected in #{plugin_type} plugin #{plugin_klass}")
        result.capabilities.each do |cap|
          cap_klass = Class.new(Capability).tap do |k|
            k.class_eval("def self.#{cap.name}(environment, *args){ plugin_client.host_capability(" \
              "Vagrant::Proto::HostCapabilityRequest.new(" \
              "environment: JSON.dump(environment), arguments: JSON.dump(args)," \
              "capability: Vagrant::Proto::SystemCapability.new(" \
              "name: '#{cap.name}', platform: '#{cap.platform}'))) }")
          end
          cap_klass.plugin_client = client
          plugin_klass.host_capability(cap.platform, cap.name) { cap_klass }
        end
      end

      # Fetch any defined provider capabilites for given plugin and register
      # capabilities within given plugin class
      #
      # @param [Vagrant::Proto::ProviderCapabilities::Stub] client Plugin client
      # @param [Class] plugin_klass Plugin class to register capabilities
      # @param [Symbol] plugin_type Type of plugin
      def self.generate_provider_capabilities(client, plugin_klass, plugin_type)
        logger.debug("checking for provider capabilities in #{plugin_type} plugin #{plugin_klass}")
        result = client.provider_capabilities(Vagrant::Proto::Empty.new)
        return if result.capabilities.empty?
        logger.debug("provider capabilities support detected in #{plugin_type} plugin #{plugin_klass}")
        result.capabilities.each do |cap|
          cap_klass = Class.new(Capability).tap do |k|
            k.class_eval("def self.#{cap.name}(machine, *args){ plugin_client.provider_capability(" \
              "Vagrant::Proto::ProviderCapabilityRequest.new(" \
              "machine: JSON.dump(machine), arguments: JSON.dump(args)," \
              "capability: Vagrant::Proto::ProviderCapability.new(" \
              "name: '#{cap.name}', provider: '#{cap.provider}'))) }")
          end
          cap_klass.plugin_client = client
          plugin_klass.provider_capability(cap.provider, cap.name) { cap_klass }
        end
      end
    end
  end
end
