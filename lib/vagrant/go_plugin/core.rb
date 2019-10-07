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
          ffi_lib File.expand_path("./go-plugin.so", File.dirname(__FILE__))

          typedef :strptr, :plugin_result

          # stdlib functions
          if FFI::Platform.windows?
            attach_function :free, :_free, [:pointer], :void
          else
            attach_function :free, [:pointer], :void
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

    # Simple module to load into plugin wrapper classes
    # to provide expected functionality
    module GRPCPlugin
      module ClassMethods
        def plugin_client
          @_plugin_client
        end

        def plugin_client=(c)
          if @_plugin_client
            raise ArgumentError, "Plugin client has already been set"
          end
          @_plugin_client = c
        end
      end

      module InstanceMethods
        def plugin_client
          self.class.plugin_client
        end
      end

      def self.included(klass)
        klass.include(Vagrant::Util::Logger)
        klass.include(InstanceMethods)
        klass.extend(ClassMethods)
      end
    end
  end
end
