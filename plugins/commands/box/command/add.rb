require 'optparse'

module VagrantPlugins
  module CommandBox
    module Command
      class Add < Vagrant.plugin("2", :command)
        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant box add <name> <url> [--provider provider] [-h]"
            o.separator ""

            o.on("-f", "--force", "Overwrite an existing box if it exists.") do |f|
              options[:force] = f
            end

            o.on("--provider provider", String,
                 "The provider that backs the box.") do |p|
              options[:provider] = p
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

          # Get the provider if one was set
          provider = nil
          provider = options[:provider].to_sym if options[:provider]

          @env.action_runner.run(Vagrant::Action.action_box_add, {
            :box_name     => argv[0],
            :box_provider => provider,
            :box_url      => argv[1]
          })

          # Success, exit status 0
          0
        end
      end
    end
  end
end
