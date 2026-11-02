# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      # Mapper defines a single mapping from a source
      # value to a destination value
      class Mapper
        extend Util::HasLogger
        # Track all known mappers
        @@mappers = []
        @@init = false

        # @return [Array<Class>] list of known mappers
        def self.registered
          @@mappers
        end

        # Represents an input argument for a mapper
        class Input
          # @return [String] optional name for input
          attr_reader :name
          # @return [Class] type of the argument
          attr_reader :type
          # @return [#call] callable that can validate argument
          attr_reader :validator
          # @return [Boolean] Only allow the origin value to be connected to this input
          attr_reader :origin_restricted

          # Create a new input
          #
          # @param type [Class] Type of the input

          # @param validator [Callable] Callable to validate argument (optional)
          # @yield Callable to validate argument (optional)
          def initialize(type:, validator: nil, origin_restricted: false, &block)
            if !type.is_a?(Class) && !type.is_a?(Module)
              raise ArgumentError,
                "Type must be constant type (given: #{type})"
            end
            @type = type
            if validator && block
              raise ArgumentError,
                "Only one of `:validator' option or block may be used"
            end
            @validator = validator || block
            @validator = lambda{ |_| true } if !@validator

            if !@validator.respond_to?(:call)
              raise ArgumentError,
                "Validator must be callable"
            end
            @origin_restricted = origin_restricted
          end

          # Check if given argument is valid for this input
          #
          # @param arg [Object] Argument to validate
          # @return [Boolean]
          def valid?(arg)
            if !arg.is_a?(type) && arg != type
              return false
            end
            return true if arg.is_a?(Class)
            validator.call(arg)
          end
        end

        # Registers class as a known mapper
        def self.inherited(klass)
          @@mappers << klass
        end

        def self.generate_anys
          return if @@init
          @@mappers.each do |klass|
            # For any mapper that outputs a protobuf message,
            # automatically provide an Any mapper.
            m  = klass.new
            if m.output.ancestors.include?(Google::Protobuf::MessageExts)
              names = registered.map(&:name)
              next if names.include?("#{m.output.name}ToAny")
              logger.trace { "generating new Any converter #{m.output.name}ToAny" }
              Class.new(Mapper).class_eval("
                def self.name
                  '#{m.output.name}' + 'ToAny'
                end

                def initialize
                  super(
                    inputs: [Input.new(type: #{m.output.name})],
                    output: Google::Protobuf::Any,
                    func: method(:converter)
                  )
                end

                def converter(v)
                  Google::Protobuf::Any.pack(v)
                end

                def to_s
                  '<#{m.output.name}' + 'ToAny:' + object_id.to_s + '>'
                end
                ")
            end
          end
          @@init = true
        end

        include Util::HasLogger

        # @return [Array<Input>] list of inputs for mapper
        attr_reader :inputs
        # @return [Class, nil] type of output
        attr_reader :output
        # @return [#call] callable to perform mapping
        attr_reader :func

        # Create a new mapper instance
        #
        # @param inputs [Array<Input>] List of inputs for mapper
        # @param output [Class] Type of output value
        # @param func [#call] Callable to perform mapping
        def initialize(inputs:, output:, func:)
          Array(inputs).each do |i|
            if !i.is_a?(Input)
              raise ArgumentError,
                "Inputs must be `Input' type (given: #{i.inspect})"
            end
          end
          @inputs = Array(inputs)
          if !output.is_a?(Class)
            raise ArgumentError,
              "Output must be Class type (given: #{output.inspect} / #{output.class})"
          end
          @output = output
          if !func.respond_to?(:call)
            raise ArgumentError,
              "Func must be callable"
          end
          @func = func
        end

        # Calls the mapper with the given arguments
        def call(*args)
          if args.size > inputs.size
            raise ArgumentError,
              "Expected `#{inputs.size}' arguments but received `#{args.size}'"
          end
          args.each_with_index do |a, i|
            if !inputs[i].valid?(a)
              raise ArgumentError,
                "Invalid argument provided `#{a.class}' for input `#{inputs[i].type}'"
            end
          end
          result = func.call(*args)
          if !result.is_a?(output)
            raise TypeError,
              "Expected output type of `#{output}', got `#{result.class}' (in #{self.class})"
          end
          result
        end

        # @return [Boolean] returns true arguments contain needed inputs
        def satisfied_by?(*args)
          begin
            determine_inputs(*args)
            true
          rescue ArgumentError
            false
          end
        end

        # Builds argument list for mapper call with given arguments
        #
        # @return [Array<Object>]
        def determine_inputs(*args)
          Array.new.tap do |found_inputs|
            inputs.each do |input|
              value = args.detect do |arg|
                input.valid?(arg)
              end
              if value.nil? && input.type != NilClass
                logger.error { "missing input for type `#{input.type}' - #{args.inspect}" }
                raise ArgumentError,
                  "Failed to locate required argument of type `#{input.type}'"
              end
              found_inputs << value
            end
          end
        end
      end
    end
  end
end
