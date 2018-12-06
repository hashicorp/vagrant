require "vagrant/go_plugin/core"

module Vagrant
  module GoPlugin
    module ProviderPlugin
      # Helper class for wrapping actions in a go-plugin into
      # something which can be used by Vagrant::Action::Builder
      class Action
        # @return [String] provider name associated to this class
        def self.provider_name
          @provider_name
        end

        # Set the provider name for this class
        #
        # @param [String] n provider name
        # @return [String]
        # @note can only be set once
        def self.provider_name=(n)
          if @provider_name
            raise ArgumentError.new("Class provider name has already been set")
          end
          @provider_name = n.to_s.dup.freeze
        end

        # @return [String] action name associated to this class
        def self.action_name
          @action_name
        end

        # Set the action name for this class
        #
        # @param [String] n action name
        # @return [String]
        # @note can only be set once
        def self.action_name=(n)
          if @action_name
            raise ArgumentError.new("Class action name has already been set")
          end
          @action_name = n.to_s.dup.freeze
        end

        def initialize(app, env)
          @app = app
        end

        def call(env)
          env_data = env_dump(env)
          result = VagrantGoPlugin._provider_run_action(
            self.class.go_plugin_name, self.class.go_action_name,
            env_data, env[:machine].environment.dump)
          result.each_pair do |k, v|
            env[k] = v
          end
          @app.call(env)
        end
      end

      # Helper class used to provide a wrapper around a go-plugin
      # provider so that it can be interacted with normally within
      # Vagrant
      class Provider < Vagrant.plugin("2", :provider)
        # @return [Vagrant::Machine]
        attr_reader :machine

        # @return [String] plugin name associated to this class
        def self.go_plugin_name
          @go_plugin_name
        end

        # Set the plugin name for this class
        #
        # @param [String] n plugin name
        # @return [String]
        # @note can only be set once
        def self.go_plugin_name=(n)
          if @go_plugin_name
            raise ArgumentError.new("Class plugin name has already been set")
          end
          @go_plugin_name = n
        end

        # @return [String]
        def self.name
          go_plugin_name.to_s.capitalize.tr("_", "")
        end

        def initialize(machine)
          @machine = machine
        end

        # @return [String] name of the provider plugin for this class
        def provider_name
          self.class.go_plugin_name
        end

        # Get callable action by name
        #
        # @param [Symbol] name name of the action
        # @return [Class] callable action class
        def action(name)
          ProviderPlugin.interface.action(provider_name, name.to_s, machine)
        end

        # Execute capability with given name
        #
        # @param [Symbol] name Name of the capability
        # @return [Object]
        def capability(name, *args)
          args = args.map do |arg|
            arg.response_to(:to_json) ? arg.to_json : arg.to_s
          end
          result = ProviderPlugin.interface.capability(provider_name, args.to_json, machine)
          begin
            JSON.load(result)
          rescue
            result
          end
        end

        # @return [Boolean] provider is installed
        def is_installed?
          ProviderPlugin.interface.is_installed(provider_name, machine)
        end

        # @return [Boolean] provider is usable
        def is_usable?
          ProviderPlugin.interface.is_usable(provider_name, machine)
        end

        # @return [nil]
        def machine_id_changed
          ProviderPlugin.interface.machine_id_changed(provider_name, machine)
          nil
        end

        # @return [Hash] SSH information
        def ssh_info
          ProviderPlugin.interface.ssh_info(provider_name, machine)
        end

        # @return [Vagrant::MachineState]
        def state
          ProviderPlugin.interface.state(provider_name, machine)
        end
      end

      def self.interface
        unless @_interface
          @_interface = Interface.new
        end
        @_interface
      end

      class Interface
        include GoPlugin::Core

        typedef :string, :action_name
        typedef :string, :action_data
        typedef :string, :capability_name
        typedef :string, :capability_data
        typedef :string, :provider_name

        # provider plugin functions
        attach_function :_provider_action, :ProviderAction,
          [:provider_name, :action_name, :vagrant_machine], :plugin_result

        attach_function :_provider_capability, :ProviderCapability,
          [:provider_name, :capability_name, :capability_data, :vagrant_machine], :plugin_result

        attach_function :_provider_is_installed, :ProviderIsInstalled,
          [:provider_name, :vagrant_machine], :plugin_result

        attach_function :_provider_is_usable, :ProviderIsUsable,
          [:provider_name, :vagrant_machine], :plugin_result

        attach_function :_provider_machine_id_changed, :ProviderMachineIdChanged,
          [:provider_name, :vagrant_machine], :plugin_result

        attach_function :_provider_run_action, :ProviderRunAction,
          [:provider_name, :action_name, :action_data, :vagrant_machine], :plugin_result

        attach_function :_provider_ssh_info, :ProviderSshInfo,
          [:provider_name, :vagrant_machine], :plugin_result

        attach_function :_provider_state, :ProviderState,
          [:provider_name, :vagrant_machine], :plugin_result

        attach_function :_list_providers, :ListProviders, [], :plugin_result

        # List of provider plugins currently available
        #
        # @return [Array<String>]
        def list_providers
          result, ptr = _list_providers
          load_result(result, ptr) || []
        end

        # Get callable action from a provider plugin
        #
        # @param [String] provider_name provider name for action
        # @param [String] action_name name of requested action
        # @param [Vagrant::Machine] machine instance of guest
        # @return [Action]
        def action(provider_name, action_name, machine)
          result = load_result { _provider_action(provider_name,
            action_name, dump_machine(machine)) }
          klasses = result.map do |klass_name|
            if klass_name.start_with?("self::")
              action_name = klass_name.split("::", 2).last
              klass = Class.new(Action)
              klass.go_provider_name = provider_name
              klass.go_action_name = action_name
              klass.class_eval do
                def self.name
                  "#{provider_name.capitalize}#{action_name.capitalize}".tr("_", "")
                end
              end
              klass
            else
              klass_name.split("::").inject(Object) do |memo, const|
                if memo.const_defined?(const)
                  memo.const_get(const)
                else
                  raise NameError.new "Unknown action class `#{klass_name}`"
                end
              end
            end
          end
          Vagrant::Action::Builder.new.tap do |builder|
            klasses.each do |action_class|
              builder.use action_class
            end
          end
        end

        def capability
        end

        # Check if provider has requested capability
        #
        # @param [String] provider_name provider name for request
        # @param [String] capability_name name of the capability
        # @param [Vagrant::Machine] machine instance of guest
        # @return [Boolean]
        def has_capability(provider_name, capability_name, machine)
          result = load_result { _provider_has_capability(provider_name,
            capability_name, dump_machine(machine)) }
          result
        end

        # Check if provider is installed
        #
        # @param [String] provider_name provider name for request
        # @param [Vagrant::Machine] machine instance of guest
        # @return [Boolean]
        def is_installed(provider_name, machine)
          result = load_result { _provider_is_installed(provider_name,
            dump_machine(machine)) }
          result
        end

        # Check if provider is usable
        #
        # @param [String] provider_name provider name for request
        # @param [Vagrant::Machine] machine instance of guest
        # @return [Boolean]
        def is_usable(provider_name, machine)
          result = load_result { _provider_is_usable(provider_name,
            dump_machine(machine)) }
          result
        end

        # Called when the ID of a machine has changed
        #
        # @param [String] provider_name provider name for request
        # @param [Vagrant::Machine] machine instance of guest
        def machine_id_changed(provider_name, machine)
          load_result { _provider_machine_id_changed(provider_name, dump_machine(machine)) }
        end

        # Get SSH info for guest
        #
        # @param [String] provider_name provider name for request
        # @param [Vagrant::Machine] machine instance of guest
        # @return [Hash] SSH information
        def ssh_info(provider_name, machine)
          load_result { _provider_ssh_info(provider_name, dump_machine(machine)) }
        end

        # Get state of machine
        #
        # @param [String] provider_name provider name for request
        # @param [Vagrant::Machine] machine instance of guest
        # @return [Vagrant::MachineState]
        def state(provider_name, machine)
          result = load_result { _provider_state(provider_name, dump_machine(machine)) }
          Vagrant::MachineState.new(result[:id],
            result[:short_description], result[:long_description])
        end

        # Load any detected provider plugins
        def load!
          if !@loaded
            @loaded = true
            logger.debug("provider go-plugins have not been loaded... loading")
            list_providers.each do |p_name, p_details|
              logger.debug("loading go-plugin provider #{p_name}. details - #{p_details}")
              # Create new provider class wrapper
              provider_klass = Class.new(Provider)
              provider_klass.go_plugin_name = p_name
              # Create new plugin to register the provider
              plugin_klass = Class.new(Vagrant.plugin("2"))
              # Define the plugin
              plugin_klass.class_eval do
                name "#{p_name} Provider"
                description p_details[:description]
              end
              # Register the provider
              plugin_klass.provider(p_name.to_sym, priority: p_details.fetch(:priority, 0)) do
                provider_klass
              end
              # Register any configuration support
              ConfigPlugin.interface.generate_config(p_name, :provider, plugin_klass)
              # Register any guest capabilities
              CapabilityPlugin.interface.generate_guest_capabilities(p_name, :provider, plugin_klass)
              # Register any host capabilities
              CapabilityPlugin.interface.generate_host_capabilities(p_name, :provider, plugin_klass)
              # Register any provider capabilities
              CapabilityPlugin.interface.generate_provider_capabilities(p_name, :provider, plugin_klass)
              logger.debug("completed loading provider go-plugin #{p_name}")
              logger.info("loaded go-plugin provider - #{p_name}")
            end
          else
            logger.warn("provider go-plugins have already been loaded. ignoring load request.")
          end
        end
      end
    end
  end
end
