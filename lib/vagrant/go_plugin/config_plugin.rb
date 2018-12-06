require "vagrant/go_plugin/core"

module Vagrant
  module GoPlugin
    # Contains all configuration functionality for go-plugin
    module ConfigPlugin
      # Config plugin class used with go-plugin
      class Config < Vagrant.plugin("2", :config)
        include TypedGoPlugin

        def finalize!
          data = local_data
          result = ConfigPlugin.interface.finalize(plugin_name, plugin_type, data)
          result.each do |key, value|
            next if data[key] == value
            instance_variable_set("@#{key}", value)
          end
          self
        end

        def validate(machine)
          ConfigPlugin.interface.validate(plugin_name, plugin_type, local_data, machine)
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

      # @return [Interface]
      def self.interface
        unless @_interface
          @_interface = Interface.new
        end
        @_interface
      end

      # Config interface to access go-plugin
      class Interface
        include GoPlugin::Core

        typedef :string, :config_name
        typedef :string, :config_data
        typedef :string, :plugin_type

        attach_function :_config_attributes, :ConfigAttributes,
          [:plugin_name, :plugin_type], :plugin_result
        attach_function :_config_load, :ConfigLoad,
          [:plugin_name, :plugin_type, :config_data], :plugin_result
        attach_function :_config_validate, :ConfigValidate,
          [:plugin_name, :plugin_type, :config_data, :vagrant_machine], :plugin_result
        attach_function :_config_finalize, :ConfigFinalize,
          [:plugin_name, :plugin_type, :config_data], :plugin_result

        # List of all supported configuration attribute names
        #
        # @param [String] plugin_name Name of plugin
        # @param [String] plugin_type Type of plugin
        # @return [Array<String>] List of attribute names
        def attributes(plugin_name, plugin_type)
          load_result { _config_attributes(plugin_name, plugin_type.to_s) }
        end

        # Load configuration data
        #
        # @param [String] plugin_name Name of plugin
        # @param [String] plugin_type Type of plugin
        # @param [Hash] data Configuration data
        # @return [Hash] Configuration data
        def load(plugin_name, plugin_type, data)
          load_result { _config_load(plugin_name, plugin_type, JSON.dump(data)) }
        end

        # Validate configuration data
        #
        # @param [String] plugin_name Name of plugin
        # @param [String] plugin_type Type of plugin
        # @param [Hash] data Configuration data
        # @param [Vagrant::Machine] machine Guest machine
        # @return [Hash] Any validation errors
        def validate(plugin_name, plugin_type, data, machine)
          load_result { _config_validate(plugin_name, plugin_type, dump_config(data), dump_machine(machine)) }
        end

        # Finalize the configuration data
        #
        # @param [String] plugin_name Name of plugin
        # @param [String] plugin_type Type of plugin
        # @param [Hash] data Configuration data
        # @return [Hash] Configuration data
        def finalize(plugin_name, plugin_type, data)
          load_result { _config_finalize(plugin_name, plugin_type, dump_config(data)) }
        end

        # Serialize configuration data
        #
        # @param [Hash] d Configuration data
        # @return [String]
        def dump_config(d)
          JSON.dump(d)
        end

        # Fetch any defined configuration support from the given plugin
        # and register it within the given plugin class
        #
        # @param [String] plugin_name Name of plugin
        # @param [String] plugin_type Type of plugin
        # @param [Class] plugin_klass Plugin class to register configuration
        def generate_config(plugin_name, plugin_type, plugin_klass)
          logger.debug("checking for configuration support in #{plugin_type} plugin #{plugin_name}")
          cattrs = attributes(plugin_name, plugin_type)
          return nil if !cattrs || cattrs.empty?
          logger.debug("configuration support detected in #{plugin_type} plugin #{plugin_name}")
          config_klass = Class.new(Config)
          cattrs.each { |att|
            config_klass.instance_eval("attr_accessor :#{att}")
          }
          config_klass.go_plugin_name = plugin_name
          config_klass.go_plugin_type = plugin_type
          plugin_klass.config(plugin_name.to_sym, plugin_type.to_sym) do
            config_klass
          end
        end
      end
    end
  end
end
