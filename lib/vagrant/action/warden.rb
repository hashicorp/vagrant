module Vagrant
  class Action
    class Warden
      attr_accessor :actions

      def initialize(middleware, env)
        @stack = []
        @actions = middleware.map { |m| finalize_middleware(m, env) }.reverse
      end

      def call(env)
        return if @actions.empty?
        @stack.push(@actions.pop).last.call(env)
      end

      def finalize_middleware(middleware, env)
        klass, args, block = middleware

        if klass.is_a?(Class)
          # A middleware klass which is to be instantiated with the
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
          raise "Invalid middleware: #{middleware.inspect}"
        end
      end
    end
  end
end
