module VagrantPlugins
  module CommunicatorWinRM
    # Handles loading and applying all available WinRM command filters
    class CommandFilter
      @@cmd_filters = [
        "cat",
        "chmod",
        "chown",
        "grep",
        "rm",
        "test",
        "uname",
        "which",
        "mkdir",
      ]

      # Filter the given Vagrant command to ensure compatibility with Windows
      #
      # @param [String] The Vagrant shell command
      # @returns [String] Windows runnable command or empty string
      def filter(command)
        command_filters.each { |c| command = c.filter(command) if c.accept?(command) }
        command
      end

      # All the available Linux command filters
      #
      # @returns [Array] All Linux command filter instances
      def command_filters
        @command_filters ||= create_command_filters()
      end

      private

      def create_command_filters
        [].tap do |filters|
          @@cmd_filters.each do |cmd|
            require_relative "command_filters/#{cmd}"
            class_name = "VagrantPlugins::CommunicatorWinRM::CommandFilters::#{cmd.capitalize}"
            filters << Module.const_get(class_name).new
          end
        end
      end
    end
  end
end
