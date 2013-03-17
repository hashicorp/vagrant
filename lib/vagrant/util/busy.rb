module Vagrant
  module Util
    # Utility class which allows blocks of code to be marked as "busy"
    # with a specified interrupt handler. During busy areas of code, it
    # is often undesirable for SIGINTs to immediately kill the application.
    # This class is a helper to cleanly register callbacks to handle this
    # situation.
    class Busy
      @@registered = []
      @@mutex = Mutex.new

      class << self
        # Mark a given block of code as a "busy" block of code, which will
        # register a SIGINT handler for the duration of the block. When a
        # SIGINT occurs, the `sig_callback` proc will be called. It is up
        # to the callback to behave properly and exit the application.
        def busy(sig_callback)
          register(sig_callback)
          return yield
        ensure
          unregister(sig_callback)
        end

        # Registers a SIGINT handler. This typically is called from {busy}.
        # Callbacks are only registered once, so calling this multiple times
        # with the same callback has no consequence.
        def register(sig_callback)
          @@mutex.synchronize do
            registered << sig_callback
            registered.uniq!

            # Register the handler if this is our first callback.
            Signal.trap("INT") { fire_callbacks } if registered.length == 1
          end
        end

        # Unregisters a SIGINT handler.
        def unregister(sig_callback)
          @@mutex.synchronize do
            registered.delete(sig_callback)

            # Remove the signal trap if no more registered callbacks exist
            Signal.trap("INT", "DEFAULT") if registered.empty?
          end
        end

        # Fires all the registered callbacks.
        def fire_callbacks
          registered.reverse.each { |r| r.call }
        end

        # Helper method to get access to the class variable. This is mostly
        # exposed for tests. This shouldn't be mucked with directly, since it's
        # structure may change at any time.
        def registered; @@registered; end
      end
    end
  end
end
