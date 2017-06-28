module Vagrant
  module Util
    # This module provies a `safe_exec` method which is a drop-in
    # replacement for `Kernel.exec` which addresses a specific issue
    # which manifests on OS X 10.5 (GH-51) and perhaps other operating systems.
    # This issue causes `exec` to fail if there is more than one system
    # thread. In that case, `safe_exec` automatically falls back to
    # forking.
    class SafeExec

      @@logger = Log4r::Logger.new("vagrant::util::safe_exec")

      def self.exec(command, *args)
        # Create a list of things to rescue from. Since this is OS
        # specific, we need to do some defined? checks here to make
        # sure they exist.
        rescue_from = []
        rescue_from << Errno::EOPNOTSUPP if defined?(Errno::EOPNOTSUPP)
        rescue_from << Errno::E045 if defined?(Errno::E045)
        rescue_from << SystemCallError

        fork_instead = false
        begin
          if fork_instead
            if Vagrant::Util::Platform.windows?
              @@logger.debug("Using subprocess because windows platform")
              args = args.dup << {notify: [:stdout, :stderr]}
              result = Vagrant::Util::Subprocess.execute(command, *args) do |type, data|
                case type
                when :stdout
                  @@logger.info(data, new_line: false)
                when :stderr
                  @@logger.info(data, new_line: false)
                end
              end
              Kernel.exit(result.exit_code)
            else
              pid = fork
              Kernel.exec(command, *args)
              Process.wait(pid)
            end
          else
            if Vagrant::Util::Platform.windows?
              # Re-generate strings to ensure common encoding
              @@logger.debug("Converting command and arguments to common UTF-8 encoding for exec.")
              @@logger.debug("Command: `#{command.inspect}` Args: `#{args.inspect}`")
              command = "#{command}".force_encoding("UTF-8")
              args = args.map{|arg| "#{arg}".force_encoding("UTF-8") }
              @@logger.debug("Converted - Command: `#{command.inspect}` Args: `#{args.inspect}`")
            end
            Kernel.exec(command, *args)
          end
        rescue *rescue_from
          # We retried already, raise the issue and be done
          raise if fork_instead

          # The error manifested itself, retry with a fork.
          fork_instead = true
          retry
        end
      end
    end
  end
end
