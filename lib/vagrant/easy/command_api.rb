require "delegate"
require "optparse"

require "log4r"

require "vagrant/easy/operations"

module Vagrant
  module Easy
    # This is the API that easy commands have access to. It is a subclass
    # of Operations so it has access to all those methods as well.
    class CommandAPI < DelegateClass(Operations)
      attr_reader :argv

      def initialize(vm, argv)
        super(Operations.new(vm))

        @logger = Log4r::Logger.new("vagrant::easy::command_api")
        @argv   = argv
        @vm     = vm
      end

      # Gets the value of an argument from the command line. Many arguments
      # can be given as a parameter and the first matching one will be returned.
      #
      # @return [String]
      def arg(*names)
        @logger.info("reading args: #{names.inspect}")

        # Mangle the names a bit to add "=VALUE" to every flag.
        names = names.map do |name|
          "#{name}=VALUE"
        end

        # Create a basic option parser
        parser = OptionParser.new

        # Add on a matcher for this thing
        result = nil
        parser.on(*names) do |value|
          result = value
        end

        begin
          # The `dup` is required in @argv because the OptionParser
          # modifies it in place as it finds matching arguments.
          parser.parse!(@argv.dup)
        rescue OptionParser::MissingArgument
          # Missing argument means the argument existed but had no data,
          # so we mark it as an empty string
          result = ""
        rescue OptionParser::InvalidOption
          # Ignore!
        end

        # Return the results
        result
      end

      # Returns any extra arguments that are past a "--" on the command line.
      #
      # @return [String]
      def arg_extra
        # Split the arguments and remove the "--"
        remaining = @argv.drop_while { |v| v != "--" }
        remaining.shift

        # Return the remaining arguments
        remaining.join(" ")
      end

      # Outputs an error message to the UI.
      #
      # @param [String] message Message to send.
      def error(message)
        @vm.ui.error(message)
      end

      # Outputs a normal message to the UI. Use this for any standard-level
      # messages.
      #
      # @param [String] message Message to send.
      def info(message)
        @vm.ui.info(message)
      end

      # Outputs a success message to the UI.
      #
      # @param [String] message Message to send.
       def success(message)
        @vm.ui.success(message)
      end
    end
  end
end
