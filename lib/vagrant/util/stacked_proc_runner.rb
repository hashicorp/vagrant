module Vagrant
  module Util
    # Represents the "stacked proc runner" behavior which is used a
    # couple places within Vagrant. This allows procs to "stack" on
    # each other, then all execute in a single action. An example of
    # its uses can be seen in the {Config} class.
    module StackedProcRunner
      # Returns the proc stack. This should always be called as the
      # accessor of the stack. The instance variable itself should _never_
      # be used.
      #
      # @return [Array<Proc>]
      def proc_stack
        @_proc_stack ||= []
      end

      # Adds (pushes) a proc to the stack. The actual proc added here is
      # not executed, but merely stored.
      #
      # @param [Proc] block
      def push_proc(&block)
        proc_stack << block
      end

      # Executes all the procs on the stack, passing in the given arguments.
      # The stack is not cleared afterwords. It is up to the user of this
      # mixin to clear the stack by calling `proc_stack.clear`.
      def run_procs!(*args)
        proc_stack.each do |proc|
          proc.call(*args)
        end
      end
    end
  end
end