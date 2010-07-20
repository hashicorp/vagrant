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
    #
    # This class also handles progress meters of multiple resources and
    # handles all the proper interleaving and console updating to
    # display the progress meters in a way which doesn't conflict with
    # other incoming log messages.
    class ResourceLogger
      @@singleton_logger = nil
      @@progress_reporters = nil
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
          if env && env.config && env.config.loaded?
            @@singleton_logger ||= PlainLogger.new(env.config.vagrant.log_output)
          else
            PlainLogger.new(nil)
          end
        end

        # Resets the singleton logger (only used for testing).
        def reset_singleton_logger!
          @@singleton_logger = nil
        end

        # Returns the progress parts array which contains the various
        # progress reporters.
        def progress_reporters
          @@progress_reporters ||= {}
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
            # We clear the line in case progress reports have been going
            # out.
            print(cl_reset)
            logger.send(method, "[#{resource}] #{message}")
          end

          # Once again flush the progress reporters since we probably
          # cleared any existing ones.
          flush_progress
        end
      end

      # Sets a progress report for the resource that this logger
      # represents. This progress report is interleaved within the output.
      def report_progress(progress, total, show_parts=true)
        # Simply add the progress reporter to the list of progress
        # reporters
        self.class.progress_reporters[resource] = {
          :progress => progress,
          :total => total,
          :show_parts => show_parts
        }

        # And force an update to occur
        flush_progress
      end

      # Clears the progress report for this resource
      def clear_progress
        self.class.progress_reporters.delete(resource)
      end

      def flush_progress
        # Don't do anything if there are no progress reporters
        return if self.class.progress_reporters.length <= 0

        @@writer_lock.synchronize do
          reports = []

          # First generate all the report percentages and output
          self.class.progress_reporters.each do |name, data|
            percent = (data[:progress].to_f / data[:total].to_f) * 100
            line = "#{name}: #{percent.to_i}%"
            line << " (#{data[:progress]} / #{data[:total]})" if data[:show_parts]
            reports << line
          end

          # Output it to stdout
          print "#{cl_reset}[progress] #{reports.join(" ")}"
          $stdout.flush
        end
      end

      def cl_reset
        reset = "\r"
        reset += "\e[0K" unless Mario::Platform.windows?
        reset
      end
    end
  end
end
