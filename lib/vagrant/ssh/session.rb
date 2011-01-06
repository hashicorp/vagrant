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
