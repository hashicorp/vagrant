module Vagrant
  class Action
    # A step is a callable action that Vagrant uses to build up
    # more complex actions sequences.
    #
    # A step must specify the inputs it requires and the outputs
    # it will return, and can implement two methods: `enter` and
    # `exit` (both are optional, but a step is useless without
    # at least one).
    #
    # The inputs are guaranteed to be ready only by the time
    # `enter` is called and are available as instance variables.
    # `enter` is called first.
    #
    # `exit` is called at some point after `enter` (the exact time
    # is not guarateed) and is given one parameter: `error` which
    # is non-nil if an exception was raised at some point during
    # or after `enter` was called. The return value of `exit` does
    # nothing.
    class Step
      class UnsatisfiedRequirementsError < RuntimeError; end

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
      def call(params={})
        # Call the actual implementation
        results = nil
        begin
          results = call_enter(params)
        rescue UnsatisfiedRequirementsError
          # This doesn't get an `exit` call called since enter
          # was never even called in this case.
          raise
        rescue Exception => e
          call_exit(e)
          raise
        end

        # No exception occurred if we reach this point. Call exit.
        call_exit(nil)

        # Return the final results
        results
      end

      # This method will only call the `enter` method for the step.
      #
      # The parameters given here will be validated as the inputs for
      # the step and used to call `enter`. The results of `enter` will
      # be validated as the outputs and returned.
      #
      # @param [Hash] inputs
      # @return [Hash]
      def call_enter(inputs={})
        # Set and validate the inputs
        set_inputs(inputs)

        # Call the actual enter call
        results = nil
        results = send(:enter) if respond_to?(:enter)

        # Validate the outputs if it is enabled and the list of configured
        # outputs is not empty.
        self.class.process_output(results)
      end

      # This method will call `exit` with the given error.
      def call_exit(error)
        send(:exit, error) if respond_to?(:exit)
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
        raise UnsatisfiedRequirementsError, "Missing parameters: #{remaining}" if !remaining.empty?

        inputs.each do |key|
          instance_variable_set("@#{key}", params[key])
        end
      end
    end
  end
end
