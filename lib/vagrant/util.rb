module Vagrant
  module Util
    def error_and_exit(error)
      puts <<-error
=====================================================================
Vagrant experienced an error!

#{error.chomp}
=====================================================================
error
      exit
    end

    def logger
      # TODO: Buffer messages until config is loaded, then output them?
      if Vagrant.config.loaded?
        @logger ||= Vagrant::Logger.new(Vagrant.config.vagrant.log_output)
      else
        Vagrant::Logger.new(nil)
      end
    end
  end

  class Logger < ::Logger
    def format_message(level, time, progname, msg)
      "[#{level} #{time.strftime('%m-%d-%Y %X')}] Vagrant: #{msg}\n"
    end
  end
end

