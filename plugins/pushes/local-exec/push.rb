require "fileutils"
require "tempfile"
require "vagrant/util/subprocess"

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
        result = Vagrant::Util::Subprocess.execute(*cmd)

        if result.exit_code != 0
          raise Errors::CommandFailed,
            cmd:    cmd.join(" "),
            stdout: result.stdout,
            stderr: result.stderr
        end

        result
      end
    end
  end
end
