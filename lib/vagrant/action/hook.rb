module Vagrant
  module Action
    # This class manages hooks into existing {Builder} stacks, and lets you
    # add and remove middleware classes. This is the primary method by which
    # plugins can hook into built-in middleware stacks.
    class Hook
      # This is a hash of the middleware to prepend to a certain
      # other middleware.
      #
      # @return [Hash<Class, Array<Class>>]
      attr_reader :before_hooks

      # This is a hash of the middleware to append to a certain other
      # middleware.
      #
      # @return [Hash<Class, Array<Class>>]
      attr_reader :after_hooks

      # This is a list of the hooks to just prepend to the beginning
      #
      # @return [Array<Class>]
      attr_reader :prepend_hooks

      # This is a list of the hooks to just append to the end
      #
      # @return [Array<Class>]
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
      def before(existing, new)
        @before_hooks[existing] << new
      end

      # Add a middleware after an existing middleware.
      #
      # @param [Class] existing The existing middleware.
      # @param [Class] new The new middleware.
      def after(existing, new)
        @after_hooks[existing] << new
      end

      # Append a middleware to the end of the stack. Note that if the
      # middleware sequence ends early, then the new middleware won't
      # be run.
      #
      # @param [Class] new The middleware to append.
      def append(new)
        @append_hooks << new
      end

      # Prepend a middleware to the beginning of the stack.
      #
      # @param [Class] new The new middleware to prepend.
      def prepend(new)
        @prepend_hooks << new
      end

      # This applies the given hook to a builder. This should not be
      # called directly.
      #
      # @param [Builder] builder
      def apply(builder)
        # Prepends first
        @prepend_hooks.each do |klass|
          builder.insert(0, klass)
        end

        # Appends
        @append_hooks.each do |klass|
          builder.use(klass)
        end

        # Before hooks
        @before_hooks.each do |key, list|
          next if !builder.index(key)

          list.each do |klass|
            builder.insert_before(key, klass)
          end
        end

        # After hooks
        @after_hooks.each do |key, list|
          next if !builder.index(key)

          list.each do |klass|
            builder.insert_after(key, klass)
          end
        end
      end
    end
  end
end
