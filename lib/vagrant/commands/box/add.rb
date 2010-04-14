module Vagrant
  class Commands
    # Manages the `vagrant box` command, allowing the user to add
    # and remove boxes. This single command, given an array, determines
    # which action to take and calls the respective action method
    # (see {box_add} and {box_remove})
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