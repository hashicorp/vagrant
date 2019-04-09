require "vagrant/go_plugin/core"

module Vagrant
  module GoPlugin
    # Contains all configuration functionality for go-plugin
    module ConfigPlugin
      # Generate configuration for the parent class
      #
      # @param [Vagrant::Proto::Config::Stub] client Plugin client
      # @param [String] parent_name Parent plugin name
      # @param [Class] parent_klass Parent class to register config
      # @param [Symbol] parent_type Type of parent class (:provider, :synced_folder, etc)
      def self.generate_config(client, parent_name, parent_klass, parent_type)
        config_attrs = client.config_attributes(Vagrant::Proto::Empty.new).items
        config_klass = Class.new(Config)
        config_klass.plugin_client = client
        Array(config_attrs).each do |att|
          config_klass.instance_eval("attr_accessor :#{att}")
        end
        parent_klass.config(parent_name, parent_type) { config_klass }
      end

      # Config plugin class used with go-plugin
      class Config < Vagrant.plugin("2", :config)
        include GRPCPlugin

        # Finalize the current configuration
        def finalize!
          data = local_data
          result = plugin_client.config_finalize(Vagrant::Proto::Configuration.new(
            data: JSON.dump(data)))
          new_data = Vagrant::Util::HashWithIndifferentAccess.new(JSON.load(result.data))
          new_data.each do |key, value|
            next if data[key] == value
            instance_variable_set("@#{key}", value)
            if !self.respond_to?(key)
              self.define_singleton_method(key) { instance_variable_get("@#{key}") }
            end
          end
          self
        end

        # Validate configuration
        #
        # @param [Vagrant::Machine] machine Guest machine
        # @return [Array<String>] list of errors
        def validate(machine)
          result = plugin_client.config_validate(Vagrant::Proto::Configuration.new(
            machine: JSON.dump(machine),
            data: local_data))
          result.items
        end

        # @return [Hash] currently defined instance variables
        def local_data
          data = Vagrant::Util::HashWithIndifferentAccess.
            new(instance_variables_hash)
          data.delete_if { |k,v|
            k.start_with?("_")
          }
          data
        end
      end
    end
  end
end
