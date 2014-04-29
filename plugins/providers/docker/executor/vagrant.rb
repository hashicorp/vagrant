require "vagrant/util/shell_quote"

module VagrantPlugins
  module DockerProvider
    module Executor
      # The Vagrant executor runs Docker over SSH against the given
      # Vagrant-managed machine.
      class Vagrant
        def initialize(host_machine)
          @host_machine = host_machine
        end

        def execute(*cmd, **opts, &block)
          quote = '"'
          cmd   = cmd.map do |a|
            "#{quote}#{::Vagrant::Util::ShellQuote.escape(a, quote)}#{quote}"
          end.join(" ")

          # If we want stdin, we just run in a full subprocess
          return ssh_run(cmd) if opts[:stdin]

          # Add a start fence so we know when to start reading output.
          # We have to do this because boot2docker outputs a login shell
          # boot2docker version that we get otherwise and messes up output.
          start_fence = "========== VAGRANT DOCKER BEGIN =========="
          ssh_cmd     = "echo -n \"#{start_fence}\"; #{cmd}"

          stderr = ""
          stdout = ""
          fenced = false
          comm   = @host_machine.communicate
          code   = comm.execute(ssh_cmd, error_check: false) do |type, data|
            next if ![:stdout, :stderr].include?(type)
            stderr << data if type == :stderr
            stdout << data if type == :stdout

            if !fenced
              index = stdout.index(start_fence)
              if index
                fenced = true

                index += start_fence.length
                stdout = stdout[index..-1]
                stdout.chomp!

                # We're now fenced, send all the data through
                if block
                  block.call(:stdout, stdout) if stdout != ""
                  block.call(:stderr, stderr) if stderr != ""
                end
              end
            else
              # If we're already fenced, just send the data through.
              block.call(type, data) if block && fenced
            end
          end

          if code != 0
            raise Errors::ExecuteError,
              command: cmd,
              stderr: stderr.chomp,
              stdout: stdout.chomp
          end

          stdout.chomp
        end

        protected

        def ssh_run(cmd)
          @host_machine.action(
            :ssh_run,
            ssh_run_command: cmd,
          )

          ""
        end
      end
    end
  end
end
