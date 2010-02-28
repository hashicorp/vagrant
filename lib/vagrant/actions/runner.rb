module Vagrant
  module Actions
    # Base class for any class which will act as a runner
    # for actions. A runner is simply a class which will execute
    # actions.
    class Runner
      include Vagrant::Util

      class << self
        # Executes a specific action.
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
        @actions ||= []
      end

      # Add an action to the list of queued actions to execute. This method
      # appends the given action class to the end of the queue.
      def add_action(action_klass, *args)
        actions << action_klass.new(self, *args)
      end

      # Execute the actions in queue.
      def execute!(single_action=nil, *args)
        if single_action
          actions.clear
          add_action(single_action, *args)
        end

        # Call the prepare method on each once its
        # initialized, then call the execute! method
        begin
          [:prepare, :execute!].each do |method|
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
            error_and_exit(e.message)
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