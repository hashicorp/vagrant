require 'thread'

require "log4r"

module Vagrant
  # This class executes multiple actions as a single batch, parallelizing
  # the action calls if possible.
  class BatchAction
    def initialize(allow_parallel=true)
      @actions          = []
      @allow_parallel   = allow_parallel
      @logger           = Log4r::Logger.new("vagrant::batch_action")
    end

    # Add an action to the batch of actions that will be run.
    #
    # This will **not** run the action now. The action will be run
    # when {#run} is called.
    #
    # @param [Machine] machine The machine to run the action on
    # @param [Symbol] action The action to run
    # @param [Hash] options Any additional options to send in.
    def action(machine, action, options=nil)
      @actions << [machine, action, options]
    end

    # Custom runs a custom proc against a machine.
    #
    # @param [Machine] machine The machine to run against.
    def custom(machine, &block)
      @actions << [machine, block, nil]
    end

    # Run all the queued up actions, parallelizing if possible.
    #
    # This will parallelize if and only if the provider of every machine
    # supports parallelization and parallelization is possible from
    # initialization of the class.
    def run
      par = false

      if @allow_parallel
        par = true
        @logger.info("Enabling parallelization by default.")
      end

      if par
        @actions.each do |machine, _, _|
          if !machine.provider_options[:parallel]
            @logger.info("Disabling parallelization because provider doesn't support it: #{machine.provider_name}")
            par = false
            break
          end
        end
      end

      if par && @actions.length <= 1
        @logger.info("Disabling parallelization because only executing one action")
        par = false
      end

      @logger.info("Batch action will parallelize: #{par.inspect}")

      threads = []
      @actions.each do |machine, action, options|
        @logger.info("Starting action: #{machine} #{action} #{options}")

        # Create the new thread to run our action. This is basically just
        # calling the action but also contains some error handling in it
        # as well.
        thread = Thread.new do
          Thread.current[:error] = nil

          # Record our pid when we started in order to figure out if
          # we've forked...
          start_pid = Process.pid

          begin
            if action.is_a?(Proc)
              action.call(machine)
            else
              machine.send(:action, action, options)
            end
          rescue Exception => e
            # If we're not parallelizing, then raise the error. We also
            # don't raise the error if we've forked, because it'll hang
            # the process.
            raise if !par && Process.pid == start_pid

            # Store the exception that will be processed later
            Thread.current[:error] = e

            # We can only do the things below if we do not fork, otherwise
            # it'll hang the process.
            if Process.pid == start_pid
              # Let the user know that this process had an error early
              # so that they see it while other things are happening.
              machine.ui.error(I18n.t("vagrant.general.batch_notify_error"))
            end
          end

          # If we forked during the process run, we need to do a hard
          # exit here. Ruby's fork only copies the running process (which
          # would be us), so if we return from this thread, it results
          # in a zombie Ruby process.
          if Process.pid != start_pid
            # We forked.

            exit_status = true
            if Thread.current[:error]
              # We had an error, print the stack trace and exit immediately.
              exit_status = false
              error = Thread.current[:error]
              @logger.error(error.inspect)
              @logger.error(error.message)
              @logger.error(error.backtrace.join("\n"))
            end

            Process.exit!(exit_status)
          end
        end

        # Set some attributes on the thread for later
        thread[:machine] = machine

        if !par
          thread.join(THREAD_MAX_JOIN_TIMEOUT) while thread.alive?
        end
        threads << thread
      end

      errors = []

      threads.each do |thread|
        # Wait for the thread to complete
        thread.join(THREAD_MAX_JOIN_TIMEOUT) while thread.alive?

        # If the thread had an error, then store the error to show later
        if thread[:error]
          e = thread[:error]
          # If the error isn't a Vagrant error, then store the backtrace
          # as well.
          if !thread[:error].is_a?(Errors::VagrantError)
            e       = thread[:error]
            message = e.message
            message += "\n"
            message += "\n#{e.backtrace.join("\n")}"

            errors << I18n.t("vagrant.general.batch_unexpected_error",
                             machine: thread[:machine].name,
                             message: message)
          else
            errors << I18n.t("vagrant.general.batch_vagrant_error",
                             machine: thread[:machine].name,
                             message: thread[:error].message)
          end
        end
      end

      if !errors.empty?
        raise Errors::BatchMultiError, message: errors.join("\n\n")
      end
    end
  end
end
