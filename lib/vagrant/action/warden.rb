module Vagrant
  class Action
    class Warden
      attr_accessor :actions, :stack

      def initialize(actions, env)
        @stack = []
        @actions = actions.map { |m| finalize_action(m, env) }.reverse
      end

      def call(env)
        return if @actions.empty?
        @stack.push(@actions.pop).last.call(env)
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
