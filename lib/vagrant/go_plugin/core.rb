require "ffi"

module Vagrant
  module GoPlugin
    # Base module for generic setup of module/class
    module Core
      # Loads FFI and core helpers into given module/class
      def self.included(const)
        const.class_eval do
          include Vagrant::Util::Logger
          extend FFI::Library

          ffi_lib FFI::Platform::LIBC
          # TODO: Update this to include OS/ARCH details
          ffi_lib File.expand_path("./go-plugin.so", File.dirname(__FILE__))

          typedef :string, :vagrant_environment
          typedef :string, :vagrant_machine
          typedef :string, :plugin_name
          typedef :string, :plugin_type
          typedef :strptr, :plugin_result

          # stdlib functions
          if FFI::Platform.windows?
            attach_function :free, :_free, [:pointer], :void
          else
            attach_function :free, [:pointer], :void
          end

          # Generate a Hash representation of the given machine
          # which can be serialized and sent to go-plugin
          #
          # @param [Vagrant::Machine] machine
          # @return [String] JSON serialized Hash
          def dump_machine(machine)
            if !machine.is_a?(Vagrant::Machine)
              raise TypeError,
                "Expected `Vagrant::Machine` but received `#{machine.class}`"
            end
            m = {
              box: {},
              config: machine.config,
              data_dir: machine.data_dir,
              environment: dump_environment(machine.env),
              id: machine.id,
              name: machine.name,
              provider_config: machine.provider_config,
              provider_name: machine.provider_name
            }
            if machine.box
              m[:box] = {
                name: machine.box.name,
                provider: machine.box.provider,
                version: machine.box.version,
                directory: machine.box.directory.to_s,
                metadata: machine.box.metadata,
                metadata_url: machine.box.metadata_url
              }
            end
            m.to_json
          end

          # Generate a Hash representation of the given environment
          # which can be serialized and sent to a go-plugin
          #
          # @param [Vagrant::Environmment] environment
          # @return [Hash] Hash
          def dump_environment(environment)
            if !environment.is_a?(Vagrant::Environment)
              raise TypeError,
                "Expected `Vagrant::Environment` but received `#{environment.class}`"
            end
            e = {
              cwd: environment.cwd,
              data_dir: environment.data_dir,
              vagrantfile_name: environment.vagrantfile_name,
              home_path: environment.home_path,
              local_data_path: environment.local_data_path,
              tmp_path: environment.tmp_path,
              aliases_path: environment.aliases_path,
              boxes_path: environment.boxes_path,
              gems_path: environment.gems_path,
              default_private_key_path: environment.default_private_key_path,
              root_path: environment.root_path,
              primary_machine_name: environment.primary_machine_name,
              machine_names: environment.machine_names,
              active_machines: Hash[environment.active_machines]
            }
          end

          # Load given data into the provided machine. This is
          # used to update the machine with data received from
          # go-plugins
          #
          # @param [Hash] data Machine data from go-plugin
          # @param [Vagrant::Machine] machine
          # @return [Vagrant::Machine]
          def load_machine(data, machine)
            machine
          end

          # Load the result received from the extension. This will load
          # the JSON result, raise an error if detected, and properly
          # free the memory associated with the result.
          def load_result(*args)
            val, ptr = block_given? ? yield : args
            FFI::AutoPointer.new(ptr, self.method(:free))
            begin
              result = JSON.load(val)
              if !result.is_a?(Hash)
                raise TypeError.new "Expected Hash but received `#{result.class}`"
              end
              if !result["error"].to_s.empty?
                raise ArgumentError.new result["error"].to_s
              end
              result = result["result"]
              if result.is_a?(Hash)
                result = Vagrant::Util::HashWithIndifferentAccess.new(result)
              end
              result
            rescue => e
              # TODO: Customize to provide formatted output on error
              raise
            end
          end
        end
      end
    end

    module DirectGoPlugin
      def self.included(klass)
        klass.extend(ClassMethods)
        klass.include(InstanceMethods)
      end

      module ClassMethods
        # @return [String] plugin name associated to this class
        def go_plugin_name
          @go_plugin_name
        end

        def plugin_name
          go_plugin_name
        end

        # Set the plugin name for this class
        #
        # @param [String] n plugin name
        # @return [String]
        # @note can only be set once
        def go_plugin_name=(n)
          if @go_plugin_name
            raise ArgumentError.new("Class plugin name has already been set")
          end
          @go_plugin_name = n
        end

        # @return [String]
        def name
          go_plugin_name.to_s.capitalize.tr("_", "")
        end
      end

      module InstanceMethods
        def plugin_name
          self.class.go_plugin_name
        end
      end
    end

    module TypedGoPlugin
      def self.included(klass)
        klass.extend(ClassMethods)
        klass.include(InstanceMethods)
        klass.include(DirectGoPlugin)
      end

      module ClassMethods
        def go_plugin_type
          @go_plugin_type
        end

        def go_plugin_type=(t)
          if @go_plugin_type
            raise ArgumentError.new("Class plugin type has already been set")
          end
          @go_plugin_type = t.to_s
        end
      end

      module InstanceMethods
        def plugin_type
          self.class.go_plugin_type
        end
      end
    end
  end
end
