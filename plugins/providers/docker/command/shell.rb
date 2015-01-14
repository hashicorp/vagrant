module VagrantPlugins
  module DockerProvider
    module Command
      class Exec < Vagrant.plugin("2", :command)
        def self.synopsis
          "open a bash shell for a running container"
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

          # This keeps track of if we ran our action on any machines...
          any_success = false

          target_opts = { provider: :docker }
          target_opts[:single_target] = options[:pty]

          with_target_vms(argv, target_opts) do |machine|

            state = machine.state.id
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
              :exec_command,
              exec_command: "bash",
              exec_detach: options[:detach],
              exec_pty: options[:pty],
              exec_rm: options[:rm]
            )
          end

          return any_success ? 0 : 1
        end
      end
    end
  end
end
