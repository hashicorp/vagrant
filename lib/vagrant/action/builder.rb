module Vagrant
  class Action
    class Builder
      def initialize(&block)
        instance_eval(&block) if block_given?
      end

      def stack
        @stack ||= []
      end

      def use(middleware, *args, &block)
        stack << [middleware, args, block]
      end

      def to_app
        inner = @ins.last

        @ins[0...-1].reverse.inject(inner) { |a,e| e.call(a) }
      end

      def call(env)
        to_app.call(env)
      end
    end
  end
end
