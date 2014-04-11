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

        def execute(*cmd, &block)
          quote = '"'
          cmd   = cmd.map do |a|
            "#{quote}#{::Vagrant::Util::ShellQuote.escape(a, quote)}#{quote}"
          end.join(" ")

          # Add a start fence so we know when to start reading output.
          # We have to do this because boot2docker outputs a login shell
          # boot2docker version that we get otherwise and messes up output.
          start_fence = "========== VAGRANT DOCKER BEGIN =========="
          ssh_cmd     = "echo \"#{start_fence}\"; #{cmd}"

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
                index += start_fence.length
                stdout = stdout[index..-1]
                stdout.chomp!
              end
            end

            block.call(type, data) if block && fenced
          end

          if code != 0
            raise Errors::ExecuteError,
              command: cmd,
              stderr: stderr.chomp,
              stdout: stdout.chomp
          end

          stdout.chomp
        end
      end
    end
  end
end
