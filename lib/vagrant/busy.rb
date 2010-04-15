module Vagrant
  def self.busy?
    Busy.busy?
  end

  def self.busy(&block)
    Busy.busy(&block)
  end

  class Busy
    extend Vagrant::Util

    @@busy = false
    @@mutex = Mutex.new
    @@trap_thread = nil

    class << self
      def busy?
        @@busy
      end

      def busy=(val)
        @@busy = val
      end

      def busy(&block)
        @@mutex.synchronize do
          begin
            Signal.trap("INT") { wait_for_not_busy }
            Busy.busy = true
            runner = Thread.new(block) { block.call }
            runner.join
          ensure
            # In the case an exception is thrown, make sure we restore
            # busy back to some sane state.
            Busy.busy = false

            # Make sure that the trap thread completes, if it is running
            trap_thread.join if trap_thread

            # And restore the INT trap to the default
            Signal.trap("INT", "DEFAULT")
          end
        end
      end

      def wait_for_not_busy(sleeptime=5)
        if @@trap_thread
          logger.info "Exiting vagrant immediately!"
          Thread.kill(@@trap_thread)
          abort
          return # for tests
        end

        @@trap_thread ||= Thread.new do
          # Wait while the app is busy
          loop do
            break unless busy?
            logger.info "Waiting for vagrant to clean itself up..."
            sleep sleeptime
          end

          # Exit out of the entire script
          logger.info "Exiting vagrant..."
          exit
        end
      end

      # Used for testing
      def reset_trap_thread!
        @@trap_thread = nil
      end

      # Returns the trap thread
      def trap_thread
        @@trap_thread
      end
    end
  end
end
