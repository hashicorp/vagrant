require "log4r"

module Vagrant
  module Util
    module Retryable
      # Retries a given block a specified number of times in the
      # event the specified exception is raised. If the retries
      # run out, the final exception is raised.
      #
      # This code is adapted slightly from the following blog post:
      # http://blog.codefront.net/2008/01/14/retrying-code-blocks-in-ruby-on-exceptions-whatever/
      def retryable(opts=nil)
        logger = nil
        opts   = { tries: 1, on: Exception }.merge(opts || {})

        begin
          return yield
        rescue *opts[:on] => e
          if (opts[:tries] -= 1) > 0
            logger = Log4r::Logger.new("vagrant::util::retryable")
            logger.info("Retryable exception raised: #{e.inspect}")

            sleep opts[:sleep].to_f if opts[:sleep]
            retry
          end
          raise
        end
      end
    end
  end
end
