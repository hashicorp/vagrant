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

      def before(existing, new)
        @before_hooks[existing] << new
      end

      def after(existing, new)
        @after_hooks[existing] << new
      end

      def append(new)
        @append_hooks << new
      end

      def prepend(new)
        @prepend_hooks << new
      end
    end
  end
end
