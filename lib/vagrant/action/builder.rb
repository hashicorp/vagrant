module Vagrant
  module Action
    # Action builder which provides a nice DSL for building up
    # a middleware sequence for Vagrant actions. This code is based
    # heavily off of `Rack::Builder` and `ActionDispatch::MiddlewareStack`
    # in Rack and Rails, respectively.
    #
    # Usage
    #
    # Building an action sequence is very easy:
    #
    #     app = Vagrant::Action::Builder.new do
    #       use MiddlewareA
    #       use MiddlewareB
    #     end
    #
    #     Vagrant::Action.run(app)
    #
    class Builder
      # Initializes the builder. An optional block can be passed which
      # will be evaluated in the context of the instance.
      def initialize(&block)
        instance_eval(&block) if block_given?
      end

      # Returns a mergeable version of the builder. If `use` is called with
      # the return value of this method, then the stack will merge, instead
      # of being treated as a separate single middleware.
      def flatten
        lambda do |env|
          self.call(env)
        end
      end

      # Adds a middleware class to the middleware stack. Any additional
      # args and a block, if given, are saved and passed to the initializer
      # of the middleware.
      #
      # @param [Class] middleware The middleware class
      def use(middleware, *args, &block)
        # Prepend with a environment setter if args are given
        if !args.empty? && args.first.is_a?(Hash) && middleware != Env::Set
          self.use(Env::Set, args.shift, &block)
        end

        if middleware.kind_of?(Builder)
          # Merge in the other builder's stack into our own
          self.stack.concat(middleware.stack)
        else
          self.stack << [middleware, args, block]
        end

        self
      end

      # Inserts a middleware at the given index or directly before the
      # given middleware object.
      def insert(index, middleware, *args, &block)
        index = self.index(index) unless index.is_a?(Integer)
        raise "no such middleware to insert before: #{index.inspect}" unless index
        stack.insert(index, [middleware, args, block])
      end

      alias_method :insert_before, :insert

      # Inserts a middleware after the given index or middleware object.
      def insert_after(index, middleware, *args, &block)
        index = self.index(index) unless index.is_a?(Integer)
        raise "no such middleware to insert after: #{index.inspect}" unless index
        insert(index + 1, middleware, *args, &block)
      end

      # Replaces the given middlware object or index with the new
      # middleware.
      def replace(index, middleware, *args, &block)
        if index.is_a?(Integer)
          delete(index)
          insert(index, middleware, *args, &block)
        else
          insert_before(index, middleware, *args, &block)
          delete(index)
        end
      end

      # Deletes the given middleware object or index
      def delete(index)
        index = self.index(index) unless index.is_a?(Integer)
        stack.delete_at(index)
      end

      # Runs the builder stack with the given environment.
      def call(env)
        to_app(env).call(env)
      end

      # Returns the numeric index for the given middleware object.
      #
      # @param [Object] object The item to find the index for
      # @return [Integer]
      def index(object)
        stack.each_with_index do |item, i|
          return i if item[0] == object
          return i if item[0].respond_to?(:name) && item[0].name == object
        end

        nil
      end

      protected

      # Returns the current stack of middlewares. You probably won't
      # need to use this directly, and it's recommended that you don't.
      #
      # @return [Array]
      def stack
        @stack ||= []
      end

      # Converts the builder stack to a runnable action sequence.
      #
      # @param [Vagrant::Action::Environment] env The action environment
      # @return [Object] A callable object
      def to_app(env)
        # Wrap the middleware stack with the Warden to provide a consistent
        # and predictable behavior upon exceptions.
        Warden.new(stack.dup, env)
      end
    end
  end
end
