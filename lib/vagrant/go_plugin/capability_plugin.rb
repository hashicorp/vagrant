require "vagrant/go_plugin/core"

module Vagrant
  module GoPlugin
    # Contains all capability functionality for go-plugin
    module CapabilityPlugin
      # Wrapper class for go-plugin defined capabilities
      class Capability
        extend TypedGoPlugin
      end

      # @return [Interface]
      def self.interface
        unless @_interface
          @_interface = Interface.new
        end
        @_interface
      end

      # Capability interface to access go-plugin
      class Interface
        include GoPlugin::Core

        typedef :string, :capability_args
        typedef :string, :capability_name
        typedef :string, :capability_platform
        typedef :string, :capability_provider

        attach_function :_guest_capabilities, :GuestCapabilities,
          [:plugin_name, :plugin_type], :plugin_result
        attach_function :_guest_capability, :GuestCapability,
          [:plugin_name, :plugin_type, :capability_name, :capability_platform,
          :capability_args, :vagrant_machine], :plugin_result
        attach_function :_host_capabilities, :HostCapabilities,
          [:plugin_name, :plugin_type], :plugin_result
        attach_function :_host_capability, :HostCapability,
          [:plugin_name, :plugin_type, :capability_name, :capability_platform,
          :capability_args, :vagrant_environment], :plugin_result
        attach_function :_provider_capabilities, :ProviderCapabilities,
          [:plugin_name, :plugin_type], :plugin_result
        attach_function :_provider_capability, :ProviderCapability,
          [:plugin_name, :plugin_type, :capability_name, :capability_provider,
          :capability_args, :vagrant_machine], :plugin_result

        # List of supported guest capabilities
        #
        # @param [String] plugin_name Name of plugin
        # @param [String] plugin_type Type of plugin
        # @return [Array<Hash>] List of guest capabilities
        def guest_capabilities(plugin_name, plugin_type)
          load_result { _guest_capabilities(plugin_name.to_s, plugin_type.to_s) }
        end

        # Execute guest capability
        #
        # @param [String] plugin_name Name of plugin
        # @param [String] plugin_type Type of plugin
        # @param [String] cap_name Name of capability
        # @param [String] cap_plat Guest platform of capability
        # @param [Array<Object>] cap_args Arguments for the capability
        # @param [Vagrant::Machine] machine Guest machine
        def guest_capability(plugin_name, plugin_type, cap_name, cap_plat, cap_args, machine)
          load_result {
            _guest_capability(plugin_name.to_s, plugin_type.to_s, cap_name.to_s, cap_plat.to_s,
              JSON.dump(cap_args), dump_machine(machine))
          }
        end

        # List of supported host capabilities
        #
        # @param [String] plugin_name Name of plugin
        # @param [String] plugin_type Type of plugin
        # @return [Array<Hash>] List of host capabilities
        def host_capabilities(plugin_name, plugin_type)
          load_result { _host_capabilities(plugin_name.to_s, plugin_type.to_s) }
        end

        # Execute host capability
        #
        # @param [String] plugin_name Name of plugin
        # @param [String] plugin_type Type of plugin
        # @param [String] cap_name Name of capability
        # @param [String] cap_plat Host platform of capability
        # @param [Array<Object>] cap_args Arguments for the capability
        # @param [Vagrant::Environment] env Vagrant environment
        def host_capability(plugin_name, plugin_type, cap_name, cap_plat, cap_args, env)
          load_result {
            _host_capability(plugin_name.to_s, plugin_type.to_s, cap_name.to_s, cap_plat.to_s,
              JSON.dump(cap_args), dump_environment(env))
          }
        end

        # List of supported provider capabilities
        #
        # @param [String] plugin_name Name of plugin
        # @param [String] plugin_type Type of plugin
        # @return [Array<Hash>] List of provider capabilities
        def provider_capabilities(plugin_name, plugin_type)
          load_result { _provider_capabilities(plugin_name.to_s, plugin_type.to_s) }
        end

        # Execute provider capability
        #
        # @param [String] plugin_name Name of plugin
        # @param [String] plugin_type Type of plugin
        # @param [String] cap_name Name of capability
        # @param [String] cap_prov Provider of capability
        # @param [Array<Object>] cap_args Arguments for the capability
        # @param [Vagrant::Machine] machine Guest machine
        def provider_capability(plugin_name, plugin_type, cap_name, cap_prov, cap_args, machine)
          load_result {
            _provider_capability(plugin_name.to_s, plugin_type.to_s, cap_name.to_s, cap_prov.to_s,
              JSON.dump(cap_args), dump_machine(machine))
          }
        end

        # Fetch any defined guest capabilites for given plugin and register
        # capabilities within given plugin class
        #
        # @param [String] plugin_name Name of plugin
        # @param [String] plugin_type Type of plugin
        # @param [Class] plugin_klass Plugin class to register capabilities
        def generate_guest_capabilities(plugin_name, plugin_type, plugin_klass)
          logger.debug("checking for guest capabilities in #{plugin_type} plugin #{plugin_name}")
          caps = guest_capabilities(plugin_name.to_s, plugin_type.to_s)
          return if !caps || caps.empty?
          logger.debug("guest capabilities support detected in #{plugin_type} plugin #{plugin_name}")
          caps.each do |cap|
            cap_klass = Class.new(Capability).tap do |k|
              k.class_eval("def self.#{k[:name]}(machine, *args){ CapabilityPlugin.interface.guest_capability(" \
                "plugin_name, plugin_type, '#{k[:name]}', '#{k[:platform]}', args, machine) }")
            end
            plugin_klass.guest_capability(k[:platform], k[:name])
          end
        end

        # Fetch any defined host capabilites for given plugin and register
        # capabilities within given plugin class
        #
        # @param [String] plugin_name Name of plugin
        # @param [String] plugin_type Type of plugin
        # @param [Class] plugin_klass Plugin class to register capabilities
        def generate_host_capabilities(plugin_name, plugin_type, plugin_klass)
          logger.debug("checking for host capabilities in #{plugin_type} plugin #{plugin_name}")
          caps = host_capabilities(plugin_name.to_s, plugin_type.to_s)
          return if !caps || caps.empty?
          logger.debug("host capabilities support detected in #{plugin_type} plugin #{plugin_name}")
          caps.each do |cap|
            cap_klass = Class.new(Capability).tap do |k|
              k.class_eval("def self.#{k[:name]}(env, *args){ CapabilityPlugin.interface.host_capability(" \
                "plugin_name, plugin_type, '#{k[:name]}', '#{k[:platform]}', args, env) }")
            end
            plugin_klass.host_capability(k[:platform], k[:name])
          end
        end

        # Fetch any defined provider capabilites for given plugin and register
        # capabilities within given plugin class
        #
        # @param [String] plugin_name Name of plugin
        # @param [String] plugin_type Type of plugin
        # @param [Class] plugin_klass Plugin class to register capabilities
        def generate_provider_capabilities(plugin_name, plugin_type, plugin_klass)
          logger.debug("checking for provider capabilities in #{plugin_type} plugin #{plugin_name}")
          caps = provider_capabilities(plugin_name.to_s, plugin_type.to_s)
          return if !caps || caps.empty?
          logger.debug("provider capabilities support detected in #{plugin_type} plugin #{plugin_name}")
          caps.each do |cap|
            cap_klass = Class.new(Capability).tap do |k|
              k.class_eval("def self.#{k[:name]}(machine, *args){ CapabilityPlugin.interface.provider_capability(" \
                "plugin_name, plugin_type, '#{k[:name]}', '#{k[:provider]}', args, machine) }")
            end
            plugin_klass.provider_capability(k[:provider], k[:name])
          end
        end
      end
    end
  end
end
