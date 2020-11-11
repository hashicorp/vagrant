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
      # Container for Action arguments
      MiddlewareArguments = Struct.new(:parameters, :block, :keywords, keyword_init: true)
      # Item within the stack
      StackItem = Struct.new(:middleware, :arguments, keyword_init: true)

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
      def self.build(middleware, *args, **keywords, &block)
        new.use(middleware, *args, **keywords, &block)
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
      def use(middleware, *args, **keywords, &block)
        item = StackItem.new(
          middleware: middleware,
          arguments: MiddlewareArguments.new(
            parameters: args,
            keywords: keywords,
            block: block
          )
        )

        if middleware.kind_of?(Builder)
          # Merge in the other builder's stack into our own
          self.stack.concat(middleware.stack)
        else
          self.stack << item
        end

        self
      end

      # Inserts a middleware at the given index or directly before the
      # given middleware object.
      def insert(idx_or_item, middleware, *args, **keywords, &block)
        item = StackItem.new(
          middleware: middleware,
          arguments: MiddlewareArguments.new(
            parameters: args,
            keywords: keywords,
            block: block
          )
        )

        if idx_or_item.is_a?(Integer)
          index = idx_or_item
        else
          index = self.index(idx_or_item)
        end

        raise "no such middleware to insert before: #{index.inspect}" unless index

        if middleware.kind_of?(Builder)
          middleware.stack.reverse.each do |stack_item|
            stack.insert(index, stack_item)
          end
        else
          stack.insert(index, item)
        end
      end

      alias_method :insert_before, :insert

      # Inserts a middleware after the given index or middleware object.
      def insert_after(idx_or_item, middleware, *args, **keywords, &block)
        if idx_or_item.is_a?(Integer)
          index = idx_or_item
        else
          index = self.index(idx_or_item)
        end

        raise "no such middleware to insert after: #{index.inspect}" unless index
        insert(index + 1, middleware, *args, &block)
      end

      # Replaces the given middlware object or index with the new
      # middleware.
      def replace(index, middleware, *args, **keywords, &block)
        if index.is_a?(Integer)
          delete(index)
          insert(index, middleware, *args, **keywords, &block)
        else
          insert_before(index, middleware, *args, **keywords, &block)
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
          return i if item == object
          return i if item.middleware == object
          return i if item.middleware.respond_to?(:name) &&
            item.middleware.name == object
        end

        nil
      end

      # Converts the builder stack to a runnable action sequence.
      #
      # @param [Hash] env The action environment hash
      # @return [Warden] A callable object
      def to_app(env)
        # Start with a duplicate of ourself which can
        # be modified
        builder = self.dup

        # Apply all dynamic modifications of the stack. This
        # will generate dynamic hooks for all actions within
        # the stack, load any triggers for action classes, and
        # apply them to the builder's stack
        builder.apply_dynamic_updates(env)

        # Now that the stack is fully expanded, apply any
        # action hooks that may be defined so they are on
        # the outermost locations of the stack
        builder.apply_action_name(env)

        # Wrap the middleware stack with the Warden to provide a consistent
        # and predictable behavior upon exceptions.
        Warden.new(builder.stack.dup, env)
      end

      # Find any action hooks or triggers which have been defined
      # for items within the stack. Update the stack with any
      # hooks or triggers found.
      #
      # @param [Hash] env Call environment
      # @return [Builder] self
      def apply_dynamic_updates(env)
        if Vagrant::Util::Experimental.feature_enabled?("typed_triggers")
          triggers = env[:triggers]
        end

        # Use a Hook as a convenient interface for injecting
        # any applicable trigger actions within the stack
        machine_name = env[:machine].name if env[:machine]

        # Iterate over all items in the stack and apply new items
        # into the hook as they are found. Must be sure to dup the
        # stack here since we are modifying the stack in the loop.
        stack.dup.each do |item|
          hook = Hook.new

          action = item.first
          next if action.is_a?(Proc)

          # Start with adding any action triggers that may be defined
          if triggers && !triggers.find(action, :before, machine_name, :action).empty?
            hook.prepend(Vagrant::Action::Builtin::Trigger,
              action.name, triggers, :before, :action)
          end

          if triggers && !triggers.find(action, :after, machine_name, :action).empty?
            hook.append(Vagrant::Action::Builtin::Trigger,
              action.name, triggers, :after, :action)
          end

          # Next look for any hook triggers that may be defined against
          # the dynamically generated action class hooks
          if triggers && !triggers.find(action, :before, machine_name, :hook).empty?
            hook.prepend(Vagrant::Action::Builtin::Trigger,
              action.name, triggers, :before, :hook)
          end

          if triggers && !triggers.find(action, :after, machine_name, :hook).empty?
            hook.append(Vagrant::Action::Builtin::Trigger,
              action.name, triggers, :after, :hook)
          end

          # Finally load any registered hooks for dynamically generated
          # action class based hooks
          Vagrant.plugin("2").manager.find_action_hooks(action).each do |hook_proc|
            hook_proc.call(hook)
          end

          hook.apply(self, root: item)
        end

        # Apply the hook to ourself to update the stack
        self
      end

      # If action hooks have not already been set, this method
      # will perform three tasks:
      #   1. Load any hook triggers defined for the action_name
      #   2. Load any action_hooks defined from plugins
      #   3. Load any action triggers based on machine action called (not action classes)
      #
      # @param [Hash] env Call environment
      # @return [Builder]
      def apply_action_name(env)
        env[:builder_raw_applied] ||= []
        return self if !env[:action_name]

        hook = Hook.new
        machine_name = env[:machine].name if env[:machine]

        # Start with loading any hook triggers if applicable
        if Vagrant::Util::Experimental.feature_enabled?("typed_triggers") && env[:triggers]
          if !env[:triggers].find(env[:action_name], :before, machine_name, :hook).empty?
            hook.prepend(Vagrant::Action::Builtin::Trigger,
              env[:action_name], env[:triggers], :before, :hook)
          end
          if !env[:triggers].find(env[:action_name], :after, machine_name, :hook).empty?
            hook.append(Vagrant::Action::Builtin::Trigger,
              env[:action_name], env[:triggers], :after, :hook)
          end
        end

        # Next we load up all the action hooks that plugins may
        # have defined
        action_hooks = Vagrant.plugin("2").manager.action_hooks(env[:action_name])
        action_hooks.each do |hook_proc|
          hook_proc.call(hook)
        end

        # Finally load any action triggers defined. The action triggers
        # are the originally implemented trigger style. They run before
        # and after specific provider actions (like :up, :halt, etc) and
        # are different from true action triggers
        if env[:triggers] && !env[:builder_raw_applied].include?(env[:raw_action_name])
          env[:builder_raw_applied] << env[:raw_action_name]

          if !env[:triggers].find(env[:raw_action_name], :before, machine_name, :action, all: true).empty?
            hook.prepend(Vagrant::Action::Builtin::Trigger,
              env[:raw_action_name], env[:triggers], :before, :action, all: true)
          end
          if !env[:triggers].find(env[:raw_action_name], :after, machine_name, :action, all: true).empty?
            # NOTE: These after triggers need to be delayed before running to
            #       allow the rest of the call stack to complete before being
            #       run. The delayed action is prepended to the stack (not appended)
            #       to ensure it is called first, which results in it properly
            #       waiting for everything to finish before itself completing.
            builder = self.class.build(Vagrant::Action::Builtin::Trigger,
              env[:raw_action_name], env[:triggers], :after, :action, all: true)
            hook.prepend(Vagrant::Action::Builtin::Delayed, builder)
          end
        end

        # If the hooks are empty, then there was nothing to apply and
        # we can just send ourself back
        return self if hook.empty?

        # Apply all the hooks to the new builder instance
        hook.apply(self)

        self
      end
    end
  end
end
