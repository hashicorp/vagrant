module VagrantPlugins
  module DockerProvider
    module Command
      class Exec < Vagrant.plugin("2", :command)
        def self.synopsis
          "run a command in the context of a running container"
        end

        def execute
          options = {}
          options[:detach] = false
          options[:pty] = false
          options[:rm] = false

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant docker-exec [options] -- <command>"
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("--[no-]detach", "Run in the background") do |d|
              options[:detach] = d
            end

            o.on("-t", "--[no-]tty", "Allocate a pty") do |t|
              options[:pty] = t
            end
          end

          # Parse out the extra args to send to SSH, which is everything
          # after the "--"
          command     = nil
          split_index = @argv.index("--")
          if split_index
            command = @argv.drop(split_index + 1)
            @argv   = @argv.take(split_index)
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          # Show the error if we don't have "--" _after_ parse_options
          # so that "-h" and "--help" work properly.
          if !split_index
            @env.ui.error(I18n.t("docker_provider.exec_command_required"))
            return 1
          end

          target_opts = { provider: :docker }
          target_opts[:single_target] = options[:pty]

          with_target_vms(argv, target_opts) do |machine|
            # Run it!
            machine.action(
              :exec_command,
              exec_command: command,
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
