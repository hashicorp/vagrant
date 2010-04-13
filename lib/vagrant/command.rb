module Vagrant
  # This class handles commands from the command line program `vagrant`
  # and redirects them to the proper sub-command, setting up the environment
  # and executing.
  class Command
    attr_reader :env

    class <<self
      # Executes a given subcommand within the current environment (from the
      # current working directory).
      def execute(*args)
        env = Environment.load!
        env.commands.subcommand(*args)
      end
    end

    def initialize(env)
      @env = env
    end

    # Execute a subcommand with the given name and args. This method properly
    # finds the subcommand, instantiates it, and executes.
    def subcommand(*args)
      Commands::Base.dispatch(env, *args)
    end
  end
end