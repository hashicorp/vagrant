module Vagrant
  class SSH
    # A helper class which wraps around `Net::SSH::Connection::Session`
    # in order to provide basic command error checking while still
    # providing access to the actual session object.
    class Session
      include Util::Retryable

      attr_reader :session

      def initialize(session, vm)
        @session = session
        @vm      = vm
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
        channel = session.open_channel do |ch|
          ch.exec("sudo -H #{@vm.config.ssh.shell} -l") do |ch2, success|
            # Set the terminal
            ch2.send_data "export TERM=vt100\n"

            # Output each command as if they were entered on the command line
            [commands].flatten.each do |command|
              ch2.send_data "#{command}\n"
            end

            # Remember to exit or we'll hang!
            ch2.send_data "exit\n"

            # Setup the callbacks with our options so we get all the
            # stdout/stderr and error checking goodies
            setup_channel_callbacks(ch2, commands, options, block)
          end
        end

        channel.wait
        channel[:result]
      end

      # Executes a given command on the SSH session and blocks until
      # the command completes. This is an almost line for line copy of
      # the actual `exec!` implementation, except that this
      # implementation also reports `:exit_status` to the block if given.
      def exec!(commands, options=nil, &block)
        retryable(:tries => @vm.config.ssh.max_tries, :on => [IOError, Net::SSH::Disconnect], :sleep => 1.0) do
          metach = session.open_channel do |ch|
            ch.exec("#{@vm.config.ssh.shell} -l") do |ch2, success|
              # Set the terminal
              ch2.send_data "export TERM=vt100\n"

              # Output the commands as if they were entered on the command line
              [commands].flatten.each do |command|
                ch2.send_data "#{command}\n"
              end

              # Remember to exit
              ch2.send_data "exit\n"

              # Setup the callbacks
              setup_channel_callbacks(ch2, commands, options, block)
            end
          end

          metach.wait
          metach[:result]
        end
      end

      # Sets up the channel callbacks to properly check exit statuses and
      # callback on stdout/stderr.
      def setup_channel_callbacks(channel, command, options, block)
        options = { :error_check => true }.merge(options || {})

        block ||= Proc.new do |ch, type, data|
          check_exit_status(data, command, options, ch[:result]) if type == :exit_status && options[:error_check]

          ch[:result] ||= ""
          ch[:result] << data if [:stdout, :stderr].include?(type)
        end

        # Output stdout data to the block
        channel.on_data do |ch2, data|
          # This clears the screen, we want to filter it out.
          data.gsub!("\e[H", "")

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

      # Checks for an erroroneous exit status and raises an exception
      # if so.
      def check_exit_status(exit_status, commands, options=nil, output=nil)
        if exit_status != 0
          output ||= '[no output]'
          options = {
            :_error_class => Errors::VagrantError,
            :_key => :ssh_bad_exit_status,
            :command => [commands].flatten.join("\n"),
            :output => output
          }.merge(options || {})

          raise options[:_error_class], options
        end
      end
    end
  end
end
