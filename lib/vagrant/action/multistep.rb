module Vagrant
  class Action
    class MultiStep < Step
      def initialize
        @steps = []
      end

      def step(step_class, *extra_inputs)
        # Get the options hash and set the defaults
        options = {}
        options = extra_inputs.pop if extra_inputs.last.kind_of?(Hash)

        # Append the step
        @steps << [step_class, extra_inputs, options]
      end

      def call(params=nil)
        params ||= {}

        # Instantiate all the steps
        instances = @steps.map { |s, inputs, options| [s.new, inputs, options] }

        # For each step, call it with proper inputs, using the output
        # of that call as inputs to the next.
        instances.inject(params) do |inputs, data|
          step, extra_inputs, options = data

          # If there are extra inputs for this step, add them to the
          # parameters based on the initial parameters.
          extra_inputs.each do |extra_input|
            inputs[extra_input] = params[extra_input]
          end

          # If we have inputs to remap, remap them.
          if options[:map]
            options[:map].each do |from, to|
              # This sets the input to the new key while removing the
              # the old key from the same hash. Kind of sneaky, but
              # hopefully this comment makes it clear.
              inputs[to] = inputs.delete(from)
            end
          end

          # Call the actual step, using the results for the next
          # iteration.
          step.call(inputs)
        end
      end
    end
  end
end
