require "vagrant/go_plugin/core"

module Vagrant
  module GoPlugin
    module ProviderPlugin
      # Helper class for wrapping actions in a go-plugin into
      # something which can be used by Vagrant::Action::Builder
      class Action
        include GRPCPlugin

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

        # Run the action
        def call(env)
          if env.is_a?(Hash) && !env.is_a?(Vagrant::Util::HashWithIndifferentAccess)
            env = Vagrant::Util::HashWithIndifferentAccess.new(env)
          end
          machine = env.fetch(:machine, {})
          response = plugin_client.run_action(
            Vagrant::Proto::ExecuteAction.new(
              name: self.class.action_name,
              data: JSON.dump(env),
              machine: JSON.dump(machine)))
          result = JSON.load(response.result)
          if result.is_a?(Hash)
            result = Vagrant::Util::HashWithIndifferentAccess.new(result)
            result.each_pair do |k, v|
              env[k] = v
            end
          end
          @app.call(env)
        end
      end

      # Helper class used to provide a wrapper around a go-plugin
      # provider so that it can be interacted with normally within
      # Vagrant
      class Provider < Vagrant.plugin("2", :provider)
        include GRPCPlugin

        # @return [Vagrant::Machine]
        attr_reader :machine

        def initialize(machine)
          @machine = machine
        end

        # @return [String] name of the provider plugin for this class
        def name
          if !@_name
            @_name = plugin_client.name(Vagrant::Proto::Empty.new).name
          end
          @_name
        end

        # Get callable action by name
        #
        # @param [Symbol] name name of the action
        # @return [Class] callable action class
        def action(name)
          result = plugin_client.action(
            Vagrant::Proto::GenericAction.new(
              name: name.to_s,
              machine: JSON.dump(machine)))
          klasses = result.items.map do |klass_name|
            if klass_name.start_with?("self::")
              action_name = klass_name.split("::", 2).last
              klass = Class.new(Action)
              klass.plugin_client = plugin_client
              klass.action_name = action_name
              klass.class_eval do
                def self.name
                  action_name.capitalize.tr("_", "")
                end
              end
              klass
            else
              klass_name.split("::").inject(Object) do |memo, const|
                if memo.const_defined?(const)
                  memo.const_get(const)
                else
                  raise NameError, "Unknown action class `#{klass_name}`"
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

        # Execute capability with given name
        #
        # @param [Symbol] cap_name Name of the capability
        # @return [Object]
        def capability(cap_name, *args)
          r = plugin_client.provider_capability(
            Vagrant::Proto::ProviderCapabilityRequest.new(
              capability: Vagrant::Proto::ProviderCapability.new(
                name: cap_name.to_s,
                provider: name
              ),
              machine: JSON.dump(machine),
              arguments: JSON.dump(args)
            )
          )
          result = JSON.load(r.result)
          if result.is_a?(Hash)
            result = Vagrant::Util::HashWithIndifferentAccess.new(result)
          end
          result
        end

        # @return [Boolean] provider is installed
        def is_installed?
          plugin_client.is_installed(Vagrant::Proto::Machine.new(
            machine: JSON.dump(machine))).result
        end

        # @return [Boolean] provider is usable
        def is_usable?
          plugin_client.is_usable(Vagrant::Proto::Machine.new(
            machine: JSON.dump(machine))).result
        end

        # @return [nil]
        def machine_id_changed
          plugin_client.machine_id_changed(Vagrant::Proto::Machine.new(
            machine: JSON.dump(machine)))
          nil
        end

        # @return [Hash] SSH information
        def ssh_info
          result = plugin_client.ssh_info(Vagrant::Proto::Machine.new(
            machine: JSON.dump(machine))).to_hash
          Vagrant::Util::HashWithIndifferentAccess.new(result)
        end

        # @return [Vagrant::MachineState]
        def state
          result = plugin_client.state(Vagrant::Proto::Machine.new(
            machine: JSON.dump(machine)))
          Vagrant::MachineState.new(result.id,
            result.short_description, result.long_description)
        end
      end
    end
  end
end
