module Vagrant
  class Action
    class MultiStep < Step
      # This class is used as a placeholder to represent a parameter that
      # needs to be replaced at runtime. For example: A step might take a
      # parameter B that is outputted as A from a previous step. An instance
      # of this class can represent that the previous A should be remapped
      # to this new B.
      class Param
        attr_reader :name
        attr_reader :variable

        def initialize(name, variable)
          @name     = name
          @variable = variable
        end
      end

      # Represents a remapping that comes from the group inputs.
      class GroupInput < Param; end

      # Represents a remapping that comes from the output of a previous step.
      class StepOutput < Param; end

      def initialize
        @step_names = []
        @steps      = {}
      end

      # This returns a custom object that represents an input parameter
      # given to this group.
      #
      # @param [Symbol] key Parameter name of the input to use from the group.
      # @return [GroupInput] A `param` type that can be used for remappings.
      def input(key)
        return GroupInput.new(:global, key)
      end

      # This returns a custom object that represents an output parameter
      # from another step in this group.
      #
      # @param [Object] name Name of the step. This is either an explicit name
      #   like a symbol or the class for the step if it is unique.
      # @param [Symbol] output The output variable name from the step.
      # @return [StepOutput] A `param` type that can be used for remappings.
      def output(name, output)
        return StepOutput.new(name, output)
      end

      def step(step_class, *extra_inputs)
        # Determine the name for this step.
        step_name = nil
        if step_class.is_a?(Symbol)
          step_name = step_class
          step_class = extra_inputs.shift
        else
          step_name = step_class
        end

        if @steps.has_key?(step_name)
          raise NameError, "Step with name #{step_name} already exists."
        elsif !step_class.is_a?(Class)
          raise ArgumentError, "Step class must be a class."
        end

        # Get the options hash and set the defaults
        maps = {}
        maps = extra_inputs.pop if extra_inputs.last.kind_of?(Hash)

        extra_inputs.each do |direct|
          if direct.is_a?(Symbol)
            # Symbols are assumed to be inputs to this group
            direct = input(direct)
          end

          maps[direct] = direct.variable
        end

        # Append the step
        @step_names << step_name
        @steps[step_name] = [step_class, maps]
      end

      def call(params=nil)
        params ||= {}

        # Instantiate all the steps
        steps = @step_names.map do |name|
          step_class, maps = @steps[name]
          [name, step_class.new, maps]
        end

        # For each step, call it with proper inputs, using the output
        # of that call as inputs to the next.
        step_outputs = {}
        steps.inject(params) do |inputs, data|
          name, step, mappings = data

          # If we have inputs to remap, remap them.
          mappings.each do |from, to|
            if from.kind_of?(GroupInput)
              # Group inputs get their data from the initial parameters given
              # to this group.
              inputs[to] = params[from.variable]
            elsif from.kind_of?(StepOutput)
              # Step outputs get their data from a previous step's output.
              inputs[to] = step_outputs[from.name][from.variable]
            else
              # A basic remapping remaps the previous steps outputs to an
              # input for this step.
              inputs[to] = inputs.delete(from)
            end
          end

          # Call the actual step, using the results for the next
          # iteration.
          step_outputs[name] = step.call(inputs)

          # Return a shallow dup of the results
          step_outputs[name].dup
        end
      end
    end
  end
end
