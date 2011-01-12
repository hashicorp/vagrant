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

      # Opens a shell with this SSH session, which forces things like the
      # `/etc/profile` script to load, and for state to exist between commands,
      # and so on. The overhead on this is much higher than simply calling
      # {#exec!} and should really only be called when settings for the terminal
      # may be needed (for things such as a PATH modifications and so on).
      def shell
        session.shell do |sh|
          sh.on_process_run do |sh, process|
            # Enable error checking by default
            process.properties[:error_check] = true if !process.properties.has_key?(:error_check)

            process.on_finish do |p|
              # By default when a process finishes we want to check the exit
              # status so we can properly raise an exception
              self.check_exit_status(p.exit_status, p.command, p.properties) if p.properties[:error_check]
            end
          end

          yield sh

          # Exit and wait. We don't run shell commands in the background.
          sh.execute "exit", :error_check => false
          sh.wait!
        end
      end

      # Executes a given command and simply returns true/false if the
      # command succeeded or not.
      def test?(command)
        exec!(command) do |ch, type, data|
          return true if type == :exit_status && data == 0
        end

        false
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
      def check_exit_status(exit_status, command, options=nil)
        if exit_status != 0
          options = {
            :_error_class => Errors::VagrantError,
            :_key => :ssh_bad_exit_status,
            :command => command
          }.merge(options || {})

          raise options[:_error_class], options
        end
      end
    end
  end
end
