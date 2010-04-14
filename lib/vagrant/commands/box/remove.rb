module Vagrant
  class Commands
    # Removes a box permanently from the hard drive.
    module Box
      class Remove < BoxCommand
        BoxCommand.subcommand "remove", self
        description "Remove an installed box permanently."

        def execute(args=[])
          if args.length != 1
            show_help
            return
          end


          box = Vagrant::Box.find(env, args[0])
          if box.nil?
            error_and_exit(:box_remove_doesnt_exist)
            return # for tests
          end

          box.destroy
        end

        def options_spec(opts)
          opts.banner = "Usage: vagrant box remove NAME"
        end
      end
    end
  end
end