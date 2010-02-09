module Hobo
  def self.busy?
    Busy.busy?
  end

  def self.busy(&block)
    Busy.busy(&block)
  end

  class Busy
    @@busy = false
    @@mutex = Mutex.new
    class << self
      def busy?
        @@busy
      end

      def busy=(val)
        @@busy = val
      end

      def busy(&block)
        @@mutex.synchronize do
          Busy.busy = true
          yield
          Busy.busy = false
        end
        
        # In the case were an exception is thrown by the wrapped code
        # make sure to set busy to sane state and reraise the error
      rescue Exception => e
        Busy.busy = false
        raise
      end
    end
  end
end
