# A simple module to log to the console.
# Arguments will be joined together before being logged.
#
# Called as:
#  Vagrant.debug("A message", "goes here")
#  Vagrant.verbose("A message", "goes here")

# See base.rb for info on how these log levels are set.

require 'singleton'

module Vagrant
  class Log
    include Singleton

    def log_level
      @log_level || 2 # default is nolog
    end
    def log_level=(lvl)
      @log_level = lvl
    end

    def log_levels
      [:debug, :verbose, :nolog]
    end

    def debug(args)
      if log_level <= 0
        args = args.join(" ") if args.is_a?(Array)
        $stderr.puts("[debug] " + args)
      end
    end

    def verbose(args)
      if log_level <= 1
        args = args.join(" ") if args.is_a?(Array)
        $stderr.puts("[info] " + args)
      end
    end

    def log_level_name
      log_levels[self.log_level]
    end
    def log_level_name=(level_name)
      self.log_level = log_levels.index(level_name)
    end

    def raise_log_level_to(level_name)
      new_level = log_levels.index(level_name)
      if log_level > new_level
        self.log_level = new_level
      end
    end

    def set_log_level_from_options(options)
      if options[:debug]
        log_level = :debug
      elsif options[:verbose]
        log_level = :verbose
      end
    end
  end
end
