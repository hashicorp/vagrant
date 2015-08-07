module VagrantPlugins
  module DockerProvider
    module Command
      class Exec < Vagrant.plugin("2", :command)
        def self.synopsis
          "open a bash shell in a running container"
        end

        def execute
          options = {}
          options[:detach] = false
          options[:pty] = true
          options[:rm] = false

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant docker-shell [container]"
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          target_opts = { provider: :docker }
          target_opts[:single_target] = options[:pty]

          with_target_vms(argv, target_opts) do |machine|
            # Run it!
            machine.action(
              :exec_command,
              exec_command: "bash",
              exec_detach: options[:detach],
              exec_pty: options[:pty],
              exec_rm: options[:rm]
            )
          end

          # Success, exit status 0
          return 0
        end
      end
    end
  end
end
