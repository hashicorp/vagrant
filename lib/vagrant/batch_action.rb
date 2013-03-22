require 'thread'

require "log4r"

module Vagrant
  # This class executes multiple actions as a single batch, parallelizing
  # the action calls if possible.
  class BatchAction
    def initialize
      @actions = []
      @logger  = Log4r::Logger.new("vagrant::batch_action")
    end

    def action(machine, action, options=nil)
      @actions << [machine, action, options]
    end

    def run
      par = true
      @actions.each do |machine, _, _|
        if !machine.provider_options[:parallel]
          par = false
          break
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

      threads.map(&:join)
    end
  end
end
