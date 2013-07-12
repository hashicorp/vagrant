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
    #     app = Vagrant::Action::Builder.new.tap do |b|
    #       b.use MiddlewareA
    #       b.use MiddlewareB
    #     end
    #
    #     Vagrant::Action.run(app)
    #
    class Builder
      # This is the stack of middlewares added. This should NOT be used
      # directly.
      #
      # @return [Array]
      attr_reader :stack

      # This is a shortcut for a middleware sequence with only one item
      # in it. For a description of the arguments and the documentation, please
      # see {#use} instead.
      #
      # @return [Builder]
      def self.build(middleware, *args, &block)
        new.use(middleware, *args, &block)
      end

      def initialize
        @stack = []
      end

      # Implement a custom copy that copies the stack variable over so that
      # we don't clobber that.
      def initialize_copy(original)
        super

        @stack = original.stack.dup
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

        if middleware.kind_of?(Builder)
          middleware.stack.reverse.each do |stack_item|
            stack.insert(index, stack_item)
          end
        else
          stack.insert(index, [middleware, args, block])
        end
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

      # Converts the builder stack to a runnable action sequence.
      #
      # @param [Hash] env The action environment hash
      # @return [Object] A callable object
      def to_app(env)
        app_stack = nil

        # If we have action hooks, then we apply them
        if env[:action_hooks]
          builder = self.dup

          # These are the options to pass into hook application.
          options = {}

          # If we already ran through once and did append/prepends,
          # then don't do it again.
          if env[:action_hooks_already_ran]
            options[:no_prepend_or_append] = true
          end

          # Specify that we already ran, so in the future we don't repeat
          # the prepend/append hooks.
          env[:action_hooks_already_ran] = true

          # Apply all the hooks to the new builder instance
          env[:action_hooks].each do |hook|
            hook.apply(builder, options)
          end

          # The stack is now the result of the new builder
          app_stack = builder.stack.dup
        end

        # If we don't have a stack then default to using our own
        app_stack ||= stack.dup

        # Wrap the middleware stack with the Warden to provide a consistent
        # and predictable behavior upon exceptions.
        Warden.new(app_stack, env)
      end
    end
  end
end
