require "log4r"

module Vagrant
  module Action
    # The action warden is a middleware which injects itself between
    # every other middleware, watching for exceptions which are raised
    # and performing proper cleanup on every action by calling the `recover`
    # method. The warden therefore allows middlewares to not worry about
    # exceptional events, and by providing a simple callback, can clean up
    # in any erroneous case.
    #
    # Warden will "just work" behind the scenes, and is not of particular
    # interest except to those who are curious about the internal workings
    # of Vagrant.
    class Warden
      attr_accessor :actions, :stack

      def initialize(actions, env)
        @stack = []
        @actions = actions.map { |m| finalize_action(m, env) }
        @logger  = Log4r::Logger.new("vagrant::action::warden")
      end

      def call(env)
        return if @actions.empty?

        begin
          # Call the next middleware in the sequence, appending to the stack
          # of "recoverable" middlewares in case something goes wrong!
          raise Errors::VagrantInterrupt if env.interrupted?
          action = @actions.shift
          @logger.info("Calling action: #{action}")
          @stack.unshift(action).first.call(env)
          raise Errors::VagrantInterrupt if env.interrupted?
        rescue SystemExit
          # This means that an "exit" or "abort" was called. In these cases,
          # we just exit immediately.
          raise
        rescue Exception => e
          @logger.error("Error occurred: #{e}")
          env["vagrant.error"] = e

          # Something went horribly wrong. Start the rescue chain then
          # reraise the exception to properly kick us out of limbo here.
          begin_rescue(env)
          raise
        end
      end

      # Begins the recovery sequence for all middlewares which have run.
      # It does this by calling `recover` (if it exists) on each middleware
      # which has already run, in reverse order.
      def begin_rescue(env)
        @stack.each do |act|
          if act.respond_to?(:recover)
            @logger.info("Calling recover: #{act}")
            act.recover(env)
          end
        end

        # Clear stack so that warden down the middleware chain doesn't
        # rescue again.
        @stack.clear
      end

      # A somewhat confusing function which simply initializes each
      # middleware properly to call the next middleware in the sequence.
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
