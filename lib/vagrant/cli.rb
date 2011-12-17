module Vagrant
  # Manages the command line interface to Vagrant.
  class CLI < Command::Base
    def initialize(argv, env)
      @env  = env
      @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)
    end

    def execute
      if @main_args.include?("-v") || @main_args.include?("--version")
        # Version short-circuits the whole thing. Just print
        # the version and exit.
        @env.ui.info(I18n.t("vagrant.commands.version.output",
                            :version => Vagrant::VERSION),
                     :prefix => false)

        return
      end
    end
  end
end
