module Vagrant
  class Action
    # The action warden is a middleware which injects itself between
    # every other middleware, watching for exceptions which are raised
    # and performing proper cleanup on every action by calling the {#recover}
    # method. The warden therefore allows middlewares to not worry about
    # exceptional events, and by providing a simple callback, can clean up
    # in any erroneous case.
    class Warden
      attr_accessor :actions, :stack

      def initialize(actions, env)
        @stack = []
        @actions = actions.map { |m| finalize_action(m, env) }
      end

      def call(env)
        return if @actions.empty?

        begin
          # Call the next middleware in the sequence, appending to the stack
          # of "recoverable" middlewares in case something goes wrong!
          @stack.unshift(@actions.shift).first.call(env)
          raise Errors::VagrantInterrupt.new if env.interrupted?
        rescue
          # Something went horribly wrong. Start the rescue chain then
          # reraise the exception to properly kick us out of limbo here.
          begin_rescue(env)
          raise
        end
      end

      def begin_rescue(env)
        @stack.each do |act|
          act.recover(env) if act.respond_to?(:recover)
        end
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
