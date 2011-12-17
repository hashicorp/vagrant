module Vagrant
  module Command
    class Base
      protected

      # This method will split the argv given into three parts: the
      # flags to this command, the subcommand, and the flags to the
      # subcommand. For example:
      #
      #     -v status -h -v
      #
      # The above would yield 3 parts:
      #
      #     ["-v"]
      #     "status"
      #     ["-h", "-v"]
      #
      # These parts are useful because the first is a list of arguments
      # given to the current command, the second is a subcommand, and the
      # third are the commands given to the subcommand.
      #
      # @return [Array] The three parts.
      def split_main_and_subcommand(argv)
        # Initialize return variables
        main_args   = nil
        sub_command = nil
        sub_args    = []

        # We split the arguments into two: One set containing any
        # flags before a word, and then the rest. The rest are what
        # get actually sent on to the subcommand.
        argv.each_index do |i|
          if !argv[i].start_with?("-")
            # We found the beginning of the sub command. Split the
            # args up.
            main_args   = argv[0, i]
            sub_command = argv[i]
            sub_args    = argv[i + 1, argv.length - i + 1]
          end
        end

        # Handle the case that argv was empty or didn't contain any subcommand
        main_args = argv.dup if main_args.nil?

        return [main_args, sub_command, sub_args]
      end
    end
  end
end
