# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

# This adds trace level support to log4r. Since log4r
# loggers use the trace method for checking if trace
# information should be included in the output, we
# make some modifications to allow the trace check to
# still work while also supporting trace as a valid level
require "log4r/loggerfactory"

if !Log4r::Logger::LoggerFactory.respond_to?(:fake_define_methods)
  class Log4r::Logger::LoggerFactory
    class << self
      def fake_set_log(logger, lname)
        real_set_log(logger, lname)
        if lname == "TRACE"
          logger.instance_eval do
            alias :trace_as_level :trace
            def trace(*args)
              return @trace if args.empty?
              trace_as_level(*args)
            end
          end
        end
      end

      def fake_undefine_methods(logger)
        real_undefine_methods(logger)
        logger.instance_eval do
          def trace(*_)
            @trace
          end
        end
      end

      alias_method :real_undefine_methods, :undefine_methods
      alias_method :undefine_methods, :fake_undefine_methods
      alias_method :real_set_log, :set_log
      alias_method :set_log, :fake_set_log
    end
  end
end
