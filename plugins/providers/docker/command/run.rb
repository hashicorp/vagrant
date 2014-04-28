module VagrantPlugins
  module DockerProvider
    module Command
      class Run < Vagrant.plugin("2", :command)
        def self.synopsis
          "run a one-off command in the context of a container"
        end

        def execute
          options = {}
          options[:detach] = false

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant docker-run [command...]"
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("--[no-]detach", "Run in the background") do |d|
              options[:detach] = d
            end
          end

          # Parse out the extra args to send to SSH, which is everything
          # after the "--"
          split_index = @argv.index("--")
          if !split_index
            @env.ui.error(I18n.t("docker_provider.run_command_required"))
            return 1
          end

          command = @argv.drop(split_index + 1)
          @argv   = @argv.take(split_index)

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          with_target_vms(argv, provider: :docker) do |machine|
            # Run it!
            machine.action(
              :run_command,
              run_command: command,
              run_detach: options[:detach])
          end

          0
        end
      end
    end
  end
end
