require 'thread'

require "log4r"

module Vagrant
  # This class executes multiple actions as a single batch, parallelizing
  # the action calls if possible.
  class BatchAction
    def initialize(disable_parallel=false)
      @actions          = []
      @disable_parallel = disable_parallel
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

    # Run all the queued up actions, parallelizing if possible.
    #
    # This will parallelize if and only if the provider of every machine
    # supports parallelization. Parallelizing can additionally be disabled
    # by passing the option into the initializer of this class.
    def run
      par = true

      if @disable_parallel
        par = false
        @logger.info("Disabled parallelization by force.")
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

      @logger.info("Batch action will parallelize: #{par.inspect}")

      threads = []
      @actions.each do |machine, action, options|
        @logger.info("Starting action: #{machine} #{action} #{options}")

        thread = Thread.new { machine.send(:action, action, options) }
        thread.join if !par
        threads << thread
      end

      # Join the threads, which will return immediately if parallelization
      # if disabled, because we already joined on them. Otherwise, this
      # will wait for completion of all threads.
      threads.map(&:join)
    end
  end
end
