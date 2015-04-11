module VagrantPlugins
  module DockerProvider
    module Command
      class Logs < Vagrant.plugin("2", :command)
        def self.synopsis
          "outputs the logs from the Docker container"
        end

        def execute
          options = {}
          options[:follow] = false
          options[:prefix] = true

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant docker-logs [options]"
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("--[no-]follow", "Continue streaming in log output") do |f|
              options[:follow] = f
            end

            o.on("--[no-]prefix", "Prefix output with machine names") do |p|
              options[:prefix] = p
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          # This keeps track of if we ran our action on any machines...
          any_success = false

          # Start a batch action that sends all the logs to stdout. This
          # will parallelize, if enabled, across all containers that are
          # chosen.
          @env.batch do |batch|
            with_target_vms(argv) do |machine|
              if machine.provider_name != :docker
                machine.ui.output(I18n.t("docker_provider.not_docker_provider"))
                next
              end

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

              batch.custom(machine) do |m|
                execute_single(m, options)
              end
            end
          end

          # If we didn't run on any machines, then exit status 1
          return any_success ? 0 : 1
        end

        protected

        # Executes the "docker logs" command on a single machine and proxies
        # the output to our UI.
        def execute_single(machine, options)
          command = ["docker", "logs"]
          command << "--follow" if options[:follow]
          command << machine.id

          output_options = {}
          output_options[:prefix] = false if !options[:prefix]

          data_acc = ""
          machine.provider.driver.execute(*command) do |type, data|
            # Accumulate the data so we only output lines at a time
            data_acc << data

            # If we have a newline, then output all the lines we have so far
            if data_acc.include?("\n")
              lines    = data_acc.split("\n")

              if !data_acc.end_with?("\n")
                data_acc = lines.pop.chomp
              else
                data_acc = ""
              end

              lines.each do |line|
                line = " " if line == ""
                machine.ui.output(line, **output_options)
              end
            end
          end

          # Output any remaining data
          machine.ui.output(data_acc, **output_options) if !data_acc.empty?
        end
      end
    end
  end
end
