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
        config_klass = Class.new(Config).tap do |c|
          c.class_eval("def parent_name; '#{parent_name}'; end")
        end
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
          response = plugin_client.config_finalize(Vagrant::Proto::Configuration.new(
            data: JSON.dump(data)))
          result = JSON.load(response.data)
          if result && result.is_a?(Hash)
            new_data = Vagrant::Util::HashWithIndifferentAccess.new(result)
            new_data.each do |key, value|
              next if data[key] == value
              instance_variable_set("@#{key}", value)
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
            data: JSON.dump(local_data)))
          {parent_name => result.items}
        end

        # @return [Hash] currently defined instance variables
        def local_data
          Vagrant::Util::HashWithIndifferentAccess.
            new(instance_variables_hash)
        end
      end
    end
  end
end
