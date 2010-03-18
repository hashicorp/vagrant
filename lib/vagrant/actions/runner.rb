module Vagrant
  module Actions
    # Base class for any class which will act as a runner
    # for actions. A runner handles queueing up and executing actions,
    # and executing the methods of an action in the proper order. The
    # action runner also handles invoking callbacks that actions may
    # request.
    #
    # # Executing Actions
    #
    # Actions can be executed by adding them and executing them all
    # at once:
    #
    #     runner = Vagrant::Actions::Runner.new
    #     runner.add_action(FooAction)
    #     runner.add_action(BarAction)
    #     runner.add_action(BazAction)
    #     runner.execute!
    #
    # Single actions have a shorthand to be executed:
    #
    #     Vagrant::Actions::Runner.execute!(FooAction)
    #
    # Arguments may be passed into added actions by adding them after
    # the action class:
    #
    #     runner.add_action(FooAction, "many", "arguments", "may", "follow")
    #
    class Runner
      include Vagrant::Util

      class << self
        # Executes a specific action, optionally passing in any arguments to that
        # action. This method is shorthand to initializing a runner, adding a single
        # action, and executing it.
        def execute!(action_klass, *args)
          runner = new
          runner.add_action(action_klass, *args)
          runner.execute!
        end
      end

      # Returns an array of all the actions in queue. Because this
      # will persist accross calls (calling {#actions} twice will yield
      # exactly the same object), to clear or modify it, use the ruby
      # array methods which act on `self`, such as `Array#clear`.
      #
      # @return [Array]
      def actions
        @actions ||= Actions::Collection.new
      end

      # Returns the first action instance which matches the given class.
      #
      # @param [Class] action_klass The action to search for in the queue
      # @return [Object]
      def find_action(action_klass)
        actions.find { |a| a.is_a?(action_klass) }
      end

      # Add an action to the list of queued actions to execute. This method
      # appends the given action class to the end of the queue. Any arguments
      # given after the class are passed into the class constructor.
      def add_action(action_klass, *args)
        actions << action_klass.new(self, *args)
      end

      # Execute the actions in queue. This method can also optionally be used
      # to execute a single action on an instance. The syntax for executing a
      # single method on an instance is the same as the {execute!} class method.
      def execute!(single_action=nil, *args)

        if single_action
          actions.clear
          add_action(single_action, *args)
        end

        actions.duplicates!
        actions.dependencies!

        # Call the prepare method on each once its
        # initialized, then call the execute! method
        begin
          [:prepare, :execute!, :cleanup].each do |method|
            actions.each do |action|
              action.send(method)
            end
          end
        rescue Exception => e
          # Run the rescue code to do any emergency cleanup
          actions.each do |action|
            action.rescue(e)
          end

          # If its an ActionException, error and exit the message
          if e.is_a?(ActionException)
            error_and_exit(e.key, e.data)
            return
          end

          # Finally, reraise the exception
          raise
        end

        # Clear the actions
        actions.clear
      end

      # Invokes an "around callback" which invokes before_name and
      # after_name for the given callback name, yielding a block between
      # callback invokations.
      def invoke_around_callback(name, *args)
        invoke_callback("before_#{name}".to_sym, *args)
        yield
        invoke_callback("after_#{name}".to_sym, *args)
      end

      # Invokes a single callback. This method will go through each action
      # and call the method given in the parameter `name` if the action
      # responds to it.
      def invoke_callback(name, *args)
        # Attempt to call the method for the callback on each of the
        # actions
        results = []
        actions.each do |action|
          results << action.send(name, *args) if action.respond_to?(name)
        end
        results
      end
    end
  end
end
