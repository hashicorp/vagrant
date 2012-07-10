require 'optparse'

module VagrantPlugins
  module CommandBox
    module Command
      class Add < Vagrant.plugin("1", :command)
        def execute
          options = {}

          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant box add <name> <url>"
            opts.separator ""

            opts.on("-f", "--force", "Overwrite an existing box if it exists.") do |f|
              options[:force] = f
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length < 2

          # If we're force adding, then be sure to destroy any existing box if it
          # exists.
          if options[:force]
            existing = @env.boxes.find(argv[0], :virtualbox)
            existing.destroy! if existing
          end

          # Invoke the "box_add" middleware sequence.
          @env.action_runner.run(:box_add, {
            :box_name     => argv[0],
            :box_provider => :virtualbox,
            :box_url      => argv[1]
          })

          # Success, exit status 0
          0
        end
      end
    end
  end
end
