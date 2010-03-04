module Vagrant
  module Actions
    # Base class for any command actions.
    #
    # Actions are the smallest unit of functionality found within
    # Vagrant. Vagrant composes many actions together to execute
    # its complex tasks while keeping the individual pieces of a
    # task as discrete reusable actions. Actions are ran exclusively
    # by an {Runner action runner} which is simply a subclass of {Runner}.
    #
    # Actions work by implementing any or all of the following methods
    # which a {Runner} executes:
    #
    # * `prepare` - Called once for each action before any action has `execute!`
    #   called. This is meant for basic setup.
    # * `execute!` - This is where the meat of the action typically goes;
    #   the main code which executes the action.
    # * `cleanup` - This is called exactly once for each action after every
    #   other action is completed. It is meant for cleaning up any resources.
    # * `rescue` - This is called if an exception occurs in _any action_. This
    #   gives every other action a chance to clean itself up.
    #
    # For details of each step of an action, read the specific function call
    # documentation below.
    class Base
      # The {Runner runner} which is executing the action
      attr_reader :runner

      # Included so subclasses don't need to include it themselves.
      include Vagrant::Util

      # Initialization of the action, passing any arguments which may have
      # been given to the {Runner runner}. This method can be used by subclasses
      # to save any of the configuration options which are passed in.
      def initialize(runner, *args)
        @runner = runner
      end

      # This method is called once per action, allowing the action
      # to setup any callbacks, add more events, etc. Prepare is
      # called in the order the actions are defined, and the action
      # itself has no control over this.
      #
      # Examples of its usage:
      #
      # Perhaps we need an additional action only if a configuration is set:
      #
      #     def prepare
      #       @vm.actions << FooAction if Vagrant.config[:foo] == :bar
      #     end
      #
      def prepare; end

      # This method is called once, after preparing, to execute the
      # actual task. This method is responsible for calling any
      # callbacks. Adding new actions here will have unpredictable
      # effects and should never be done.
      #
      # Examples of its usage:
      #
      #     def execute!
      #       @vm.invoke_callback(:before_oven, "cookies")
      #       # Do lots of stuff here
      #       @vm.invoke_callback(:after_oven, "more", "than", "one", "option")
      #     end
      #
      def execute!; end

      # This method is called after all actions have finished executing.
      # It is meant as a place where final cleanup code can be done, knowing
      # that all other actions are finished using your data.
      def cleanup; end

      # This method is only called if some exception occurs in the chain
      # of actions. If an exception is raised in any action in the current
      # chain, then every action part of that chain has {#rescue} called
      # before raising the exception further. This method should be used to
      # perform any cleanup necessary in the face of errors.
      #
      # **Warning:** Since this method is called when an exception is already
      # raised, be _extra careful_ when implementing this method to handle
      # all your own exceptions, otherwise it'll mask the initially raised
      # exception.
      def rescue(exception); end
    end

    # An exception which occured within an action. This should be used instead of
    # {Vagrant::Util#error_and_exit error_and_exit}, since it allows the {Runner} to call
    # {Base#rescue rescue} on all the actions and properly exit. Any message
    # passed into the {ActionException} is then shown and and vagrant exits.
    class ActionException < Exception; end
  end
end
