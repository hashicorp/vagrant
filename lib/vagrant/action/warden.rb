module Vagrant
  class Action
    class Warden
      include Util
      attr_accessor :actions, :stack

      def initialize(actions, env)
        @stack = []
        @actions = actions.map { |m| finalize_action(m, env) }.reverse
      end

      def call(env)
        return if @actions.empty?

        # If the previous action passes and environment error on
        @stack.push(@actions.pop).last.call(env) unless env.error?

        # if the call action returned prematurely with an error
        begin_rescue(env) if env.error?
      end

      def begin_rescue(env)
        @stack.reverse.each do |act|
          act.rescue(env) if act.respond_to?(:rescue)
        end
        
        exit if env.interrupted?

        # Erroneous environment resulted. Properly display error message.
        error_and_exit(*env.error)
      end

      def finalize_action(action, env)
        klass, args, block = action

        if klass.is_a?(Class)
          # A action klass which is to be instantiated with the
          # app, env, and any arguments given
          klass.new(self, env, *args, &block)
        elsif klass.respond_to?(:call)
          # Make it a lambda which calls the item then forwards
          # up the chain
          lambda do |e|
            klass.call(e)
            self.call(e)
          end
        else
          raise "Invalid action: #{action.inspect}"
        end
      end
    end
  end
end
