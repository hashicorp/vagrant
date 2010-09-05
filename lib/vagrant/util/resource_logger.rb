require 'thread'

module Vagrant
  module Util
    # Represents a logger for a specific resource within Vagrant. Each
    # logger should be initialized and set to represent a single
    # resource. Each logged message will then appear in the following
    # format:
    #
    #     [resource] message
    #
    # This class is thread safe. The backing class which actually does
    # all the logging IO is protected.
    class ResourceLogger
      @@singleton_logger = nil
      @@writer_lock = Mutex.new

      # The resource which this logger represents.
      attr_reader :resource

      # The environment that this logger is part of
      attr_reader :env

      # The backing logger which actually handles the IO. This logger
      # should be a subclass of the standard library Logger, in general.
      # IMPORTANT: This logger must be thread-safe.
      attr_reader :logger

      class << self
        # Returns a singleton logger. If one has not yet be
        # instantiated, then the given environment will be used to
        # create a new logger.
        def singleton_logger(env=nil)
          @@singleton_logger ||= PlainLogger.new(env.config.vagrant.log_output)
        end

        # Resets the singleton logger (only used for testing).
        def reset_singleton_logger!
          @@singleton_logger = nil
        end
      end

      def initialize(resource, env)
        @resource = resource
        @env = env
        @logger = self.class.singleton_logger(env)
      end

      [:debug, :info, :error, :fatal].each do |method|
        define_method(method) do |message|
          @@writer_lock.synchronize do
            logger.send(method, "[#{resource}] #{message}")
          end
        end
      end
    end
  end
end
