module Hobo
  module Util
    def error_and_exit(error)
      puts <<-error
=====================================================================
Hobo experienced an error!

#{error.chomp}
=====================================================================
error
      exit
    end

    def logger
      HOBO_LOGGER
    end
  end

  class Logger < ::Logger
    def format_message(level, time, progname, msg)
      "[#{level} #{time.strftime('%m-%d-%Y %X')}] Hobo: #{msg}\n"
    end
  end
end  

