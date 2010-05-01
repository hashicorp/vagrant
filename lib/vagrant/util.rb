module Vagrant
  module Util
    def self.included(base)
      base.extend Vagrant::Util
    end

    def wrap_output
      puts "====================================================================="
      yield
      puts "====================================================================="
    end

    def error_and_exit(key, data = {})
      abort <<-error
=====================================================================
Vagrant experienced an error!

#{Translator.error_string(key, data).chomp}
=====================================================================
error
    end

    def logger
      Logger.singleton_logger
    end
  end

  class Logger < ::Logger
    @@singleton_logger = nil

    class << self
      def singleton_logger
        # TODO: Buffer messages until config is loaded, then output them?
        if Vagrant.config.loaded?
          @@singleton_logger ||= Vagrant::Logger.new(Vagrant.config.vagrant.log_output)
        else
          Vagrant::Logger.new(nil)
        end
      end

      def reset_logger!
        @@singleton_logger = nil
      end
    end

    def format_message(level, time, progname, msg)
      "[#{level} #{time.strftime('%m-%d-%Y %X')}] Vagrant: #{msg}\n"
    end
  end
end

