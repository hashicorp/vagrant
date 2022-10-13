module Vagrant
  module Action
    # This class manages hooks into existing {Builder} stacks, and lets you
    # add and remove middleware classes. This is the primary method by which
    # plugins can hook into built-in middleware stacks.
    class Hook
      # This is a hash of the middleware to prepend to a certain
      # other middleware.
      #
      # @return [Hash<Class, Array<Builder::StackItem>>]
      attr_reader :before_hooks

      # This is a hash of the middleware to append to a certain other
      # middleware.
      #
      # @return [Hash<Class, Array<Builder::StackItem>>]
      attr_reader :after_hooks

      # This is a list of the hooks to just prepend to the beginning
      #
      # @return [Array<Builder::StackItem>]
      attr_reader :prepend_hooks

      # This is a list of the hooks to just append to the end
      #
      # @return [Array<Builder::StackItem>]
      attr_reader :append_hooks

      def initialize
        @before_hooks  = Hash.new { |h, k| h[k] = [] }
        @after_hooks   = Hash.new { |h, k| h[k] = [] }
        @prepend_hooks = []
        @append_hooks  = []
      end

      # Add a middleware before an existing middleware.
      #
      # @param [Class] existing The existing middleware.
      # @param [Class] new The new middleware.
      def before(existing, new, *args, **keywords, &block)
        item = Builder::StackItem.new(
          middleware: new,
          arguments: Builder::MiddlewareArguments.new(
            parameters: args,
            keywords: keywords,
            block: block
          )
        )
        @before_hooks[existing] << item
      end

      # Add a middleware after an existing middleware.
      #
      # @param [Class] existing The existing middleware.
      # @param [Class] new The new middleware.
      def after(existing, new, *args, **keywords, &block)
        item = Builder::StackItem.new(
          middleware: new,
          arguments: Builder::MiddlewareArguments.new(
            parameters: args,
            keywords: keywords,
            block: block
          )
        )
        @after_hooks[existing] << item
      end

      # Append a middleware to the end of the stack. Note that if the
      # middleware sequence ends early, then the new middleware won't
      # be run.
      #
      # @param [Class] new The middleware to append.
      def append(new, *args, **keywords, &block)
        item = Builder::StackItem.new(
          middleware: new,
          arguments: Builder::MiddlewareArguments.new(
            parameters: args,
            keywords: keywords,
            block: block
          )
        )
        @append_hooks << item
      end

      # Prepend a middleware to the beginning of the stack.
      #
      # @param [Class] new The new middleware to prepend.
      def prepend(new, *args, **keywords, &block)
        item = Builder::StackItem.new(
          middleware: new,
          arguments: Builder::MiddlewareArguments.new(
            parameters: args,
            keywords: keywords,
            block: block
          )
        )
        @prepend_hooks << item
      end

      # @return [Boolean]
      def empty?
        before_hooks.empty? &&
          after_hooks.empty? &&
          prepend_hooks.empty? &&
          append_hooks.empty?
      end

      # This applies the given hook to a builder. This should not be
      # called directly.
      #
      # @param [Builder] builder
      def apply(builder, options={})
        if !options[:no_prepend_or_append]
          # Prepends first
          @prepend_hooks.each do |item|
            if options[:root]
              idx = builder.index(options[:root])
            else
              idx = 0
            end
            builder.insert(idx, item.middleware, *item.arguments.parameters,
              **item.arguments.keywords, &item.arguments.block)
          end

          # Appends
          @append_hooks.each do |item|
            if options[:root]
              idx = builder.index(options[:root])
              builder.insert(idx + 1, item.middleware, *item.arguments.parameters,
                **item.arguments.keywords, &item.arguments.block)
            else
              builder.use(item.middleware, *item.arguments.parameters,
                **item.arguments.keywords, &item.arguments.block)
            end
          end
        end

        # Before hooks
        @before_hooks.each do |key, list|
          next if !builder.index(key)

          list.each do |item|
            builder.insert_before(key, item.middleware, *item.arguments.parameters,
              **item.arguments.keywords, &item.arguments.block)
          end
        end

        # After hooks
        @after_hooks.each do |key, list|
          next if !builder.index(key)

          list.each do |item|
            builder.insert_after(key, item.middleware, *item.arguments.parameters,
              **item.arguments.keywords, &item.arguments.block)
          end
        end
      end
    end
  end
end
