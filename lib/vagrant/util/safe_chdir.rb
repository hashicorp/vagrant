require 'thread'

module Vagrant
  module Util
    class SafeChdir
      @@chdir_lock  = Mutex.new

      # Safely changes directory of this process by putting a lock around
      # it so that it is thread safe. This will yield a block and when the
      # block exits it changes back to the original directory.
      #
      # @param [String] dir Dir to change to temporarily
      def self.safe_chdir(dir)
        lock = @@chdir_lock

        begin
          @@chdir_lock.synchronize {}
        rescue ThreadError
          # If we already hold the lock, just create a new lock so we
          # definitely don't block and don't get an error.
          lock = Mutex.new
        end

        lock.synchronize do
          Dir.chdir(dir) do
            return yield
          end
        end
      end
    end
  end
end

