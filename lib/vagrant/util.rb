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
      VAGRANT_LOGGER
    end
  end

  class Logger < ::Logger
    def format_message(level, time, progname, msg)
      "[#{level} #{time.strftime('%m-%d-%Y %X')}] Vagrant: #{msg}\n"
    end
  end
end

