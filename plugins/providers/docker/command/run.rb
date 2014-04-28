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

          any_success = false
          with_target_vms(argv) do |machine|
            if machine.provider_name != :docker
              machine.ui.output(I18n.t("docker_provider.not_docker_provider"))
              next
            end

            state = machine.state
            if state == :host_state_unknown
              machine.ui.output(I18n.t("docker_provider.logs_host_state_unknown"))
              next
            elsif state == :not_created
              machine.ui.output(I18n.t("docker_provider.not_created_skip"))
              next
            end

            # At least one was run!
            any_success = true

            # Run it!
            machine.action(
              :run_command,
              run_command: command,
              run_detach: options[:detach])
          end

          return any_success ? 0 : 1
        end
      end
    end
  end
end
