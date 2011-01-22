module Vagrant
  class SSH
    # A helper class which wraps around `Net::SSH::Connection::Session`
    # in order to provide basic command error checking while still
    # providing access to the actual session object.
    class Session
      include Util::Retryable

      attr_reader :session

      def initialize(session)
        @session = session
      end

      # Executes a given command and simply returns true/false if the
      # command succeeded or not.
      def test?(command)
        exec!(command) do |ch, type, data|
          return true if type == :exit_status && data == 0
        end

        false
      end

      # Executes a given command on the SSH session using `sudo` and
      # blocks until the command completes. This takes the same parameters
      # as {#exec!}. The only difference is that the command can be an
      # array of commands, which will be placed into the same script.
      #
      # This is different than just calling {#exec!} with `sudo`, since
      # this command is tailor-made to be compliant with older versions
      # of `sudo`.
      def sudo!(commands, options=nil, &block)
        # First, make a temporary file to store the script
        filename = exec!("mktemp /tmp/vagrant-command-#{'X' * 10}")

        # Output each command into the temporary file
        [commands].flatten.each do |command|
          exec!("echo #{command} >> #{filename}")
        end

        # Finally, execute the file, passing in the parameters since this
        # is the expected command to run.
        exec!("sudo chmod +x #{filename}")
        exec!("sudo -i #{filename}", options, &block)
      end

      # Executes a given command on the SSH session and blocks until
      # the command completes. This is an almost line for line copy of
      # the actual `exec!` implementation, except that this
      # implementation also reports `:exit_status` to the block if given.
      def exec!(command, options=nil, &block)
        options = { :error_check => true }.merge(options || {})

        block ||= Proc.new do |ch, type, data|
          check_exit_status(data, command, options) if type == :exit_status && options[:error_check]

          ch[:result] ||= ""
          ch[:result] << data if [:stdout, :stderr].include?(type)
        end

        retryable(:tries => 5, :on => IOError, :sleep => 0.5) do
          metach = session.open_channel do |channel|
            channel.exec(command) do |ch, success|
              raise "could not execute command: #{command.inspect}" unless success

              # Output stdout data to the block
              channel.on_data do |ch2, data|
                block.call(ch2, :stdout, data)
              end

              # Output stderr data to the block
              channel.on_extended_data do |ch2, type, data|
                block.call(ch2, :stderr, data)
              end

              # Output exit status information to the block
              channel.on_request("exit-status") do |ch2, data|
                block.call(ch2, :exit_status, data.read_long)
              end
            end
          end

          metach.wait
          metach[:result]
        end
      end

      # Checks for an erroroneous exit status and raises an exception
      # if so.
      def check_exit_status(exit_status, commands, options=nil)
        if exit_status != 0
          options = {
            :_error_class => Errors::VagrantError,
            :_key => :ssh_bad_exit_status,
            :command => [commands].flatten.join("\n")
          }.merge(options || {})

          raise options[:_error_class], options
        end
      end
    end
  end
end
