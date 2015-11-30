require "fileutils"
require "tempfile"
require "vagrant/util/safe_exec"

require_relative "errors"

module VagrantPlugins
  module LocalExecPush
    class Push < Vagrant.plugin("2", :push)
      def push
        if config.inline
          execute_inline!(config.inline)
        else
          execute_script!(config.script)
        end
      end

      # Execute the inline script by writing it to a tempfile and executing.
      def execute_inline!(inline)
        script = Tempfile.new(["vagrant-local-exec-script", ".sh"])
        script.write(inline)
        script.rewind
        script.close

        execute_script!(script.path)
      ensure
        if script
          script.close
          script.unlink
        end
      end

      # Execute the script, expanding the path relative to the current env root.
      def execute_script!(path)
        path = File.expand_path(path, env.root_path)
        FileUtils.chmod("+x", path)
        execute!(path)
      end

      # Execute the script, raising an exception if it fails.
      def execute!(*cmd)
        if Vagrant::Util::Platform.windows?
          execute_subprocess!(*cmd)
        else
          execute_exec!(*cmd)
        end
      end

      private

      # Run the command as exec (unix).
      def execute_exec!(*cmd)
        Vagrant::Util::SafeExec.exec(cmd[0], *cmd[1..-1])
      end

      # Run the command as a subprocess (windows).
      def execute_subprocess!(*cmd)
        cmd = cmd.dup << { notify: [:stdout, :stderr] }
        result = Vagrant::Util::Subprocess.execute(*cmd) do |type, data|
          if type == :stdout
            @env.ui.info(data, new_line: false)
          elsif type == :stderr
            @env.ui.warn(data, new_line: false)
          end
        end

        Kernel.exit(result.exit_code)
      end
    end
  end
end
