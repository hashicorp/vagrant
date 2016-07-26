module VagrantPlugins
  module DockerProvider
    module Command
      class Exec < Vagrant.plugin("2", :command)
        def self.synopsis
          "attach to an already-running docker container"
        end

        def execute
          options = {}
          options[:detach] = false
          options[:pty] = false
          options[:interactive] = false
          options[:prefix] = true

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant docker-exec [options] [name] -- <command> [args]"
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("--[no-]detach", "Run in the background") do |d|
              options[:detach] = d
            end

            o.on("-i", "--[no-]interactive", "Keep STDIN open even if not attached") do |i|
              options[:interactive] = i
            end

            o.on("-t", "--[no-]tty", "Allocate a pty") do |t|
              options[:pty] = t
            end

            o.on("-u", "--user USER", "User or UID") do |u|
              options[:user] = u
            end

            o.on("--[no-]prefix", "Prefix output with machine names") do |p|
              options[:prefix] = p
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
            raise Errors::ExecCommandRequired
          end

          target_opts = { provider: :docker }
          target_opts[:single_target] = options[:pty]

          with_target_vms(argv, target_opts) do |machine|
            if machine.state.id != :running
              @env.ui.info("#{machine.id} is not running.")
              next
            end
            exec_command(machine, command, options)
          end

          return 0
        end

        def exec_command(machine, command, options)
          exec_cmd = %w(docker exec)
          exec_cmd << "-i" if options[:interactive]
          exec_cmd << "-t" if options[:pty]
          exec_cmd << "-u" << options[:user] if options[:user]
          exec_cmd << machine.id
          exec_cmd += options[:extra_args] if options[:extra_args]
          exec_cmd += command

          # Run this interactively if asked.
          exec_options = options
          exec_options[:stdin] = true if options[:pty]

          output = ""
          machine.provider.driver.execute(*exec_cmd, exec_options) do |type, data|
            output += data
          end

          output_options = {}
          output_options[:prefix] = false if !options[:prefix]

          if !output.empty?
            machine.ui.output(output.chomp, **output_options)
          end
        end
      end
    end
  end
end
