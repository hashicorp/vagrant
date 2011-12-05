module Vagrant
  class Action
    # A step is a callable action that Vagrant uses to build up
    # more complex actions sequences.
    #
    # A step is really just a reimplementation of a "function"
    # within the runtime of Ruby. A step advertises parameters
    # that it requires (inputs), as well as return values (outputs).
    # The `Step` class handles validating that all the required
    # parameters are set on the step as well as can validate the
    # return values.
    class Step
      # The keys given to this will be required by the step. Each key
      # should be a symbol.
      def self.input(*keys)
        inputs.concat(keys)
      end

      # The values that this step provides. Each key should be a symbol.
      def self.output(*keys)
        outputs.concat(keys)
      end

      # This is the array of required keys.
      def self.inputs
        @inputs ||= []
      end

      # The array of keys that are provided by this Step.
      def self.outputs
        @outputs ||= []
      end

      # Validates that the output matches the specification provided, and
      # raises a RuntimeError if it does not.
      def self.process_output(value)
        # The return value must be a Hash, so we just coerce it to that.
        value = {} if !value.kind_of?(Hash)

        # Verify that we have all the outputs
        missing = outputs - value.keys
        raise RuntimeError, "Missing output keys: #{missing}" if !missing.empty?

        return value
      end

      # This calls the step with the given parameters, and returns a hash
      # of the outputs.
      #
      # Additional options may be provided via the options hash at the end.
      #
      # @param [Hash] params Parameters for the step.
      # @param [Hash] options Options hash
      # @option options [Symbol] :method Method to execute.
      # @option options [Boolean] :validate_output Whether to validate the
      #   output or not.
      # @return [Hash] Output
      def call(params={}, options=nil)
        options = {
          :method => :execute,
          :validate_output => true
        }.merge(options || {})

        # Set and validate the inputs
        set_inputs(params)

        # Call the actual implementation
        results = send(options[:method])

        # Validate the outputs if it is enabled and the list of configured
        # outputs is not empty.
        results = self.class.process_output(results) if options[:validate_output]

        # Return the final results
        results
      end

      protected

      # Sets the parameters for the step.
      #
      # This will raise an exception if all the `requires` are not
      # properly met. Otherwise, the parameters are set as instance variables
      # on this instance.
      def set_inputs(params)
        inputs = self.class.inputs
        remaining = inputs - params.keys
        raise ArgumentError, "Missing parameters: #{remaining}" if !remaining.empty?

        inputs.each do |key|
          instance_variable_set("@#{key}", params[key])
        end
      end
    end
  end
end
