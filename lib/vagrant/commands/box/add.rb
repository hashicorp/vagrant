module Vagrant
  class Commands
    # Adds a box to the local filesystem, given a URI.
    module Box
      class Add < BoxCommand
        BoxCommand.subcommand "add", self
        description "Add a box"

        def execute(args)
          if args.length != 2
            show_help
            return
          end

          Vagrant::Box.add(env, args[0], args[1])
        end

        def options_spec(opts)
          opts.banner = "Usage: vagrant box add NAME URI"
        end
      end
    end
  end
end