module Vagrant
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

    # The resource which this logger represents.
    attr_reader :resource

    # The environment that this logger is part of
    attr_reader :env

    # The backing logger which actually handles the IO. This logger
    # should be a subclass of the standard library Logger, in general.
    # IMPORTANT: This logger must be thread-safe.
    attr_reader :logger

    class << self
      def singleton_logger(env=nil)
        if env && env.config.loaded?
          @@singleton_logger ||= Util::PlainLogger.new(env.config.vagrant.log_output)
        else
          Util::PlainLogger.new(nil)
        end
      end

      def reset_singleton_logger!
        @@singleton_logger = nil
      end
    end

    def initialize(resource, env)
      @resource = resource
      @env = env
      @logger = self.class.singleton_logger(env)
    end

    # TODO: The other logging methods.

    def info(message)
      logger.info("[#{resource}] #{message}")
    end
  end
end
