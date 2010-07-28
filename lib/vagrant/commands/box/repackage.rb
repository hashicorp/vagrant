module Vagrant
  class Commands
    module Box
      # Repackage a box which has been added.
      class Repackage < BoxCommand
        BoxCommand.subcommand "repackage", self
        description "Repackages a box which has already been added."

        def execute(args=[])
          return show_help if args.length != 1

          box = Vagrant::Box.find(env, args.first)
          return error_and_exit(:box_repackage_doesnt_exist) if box.nil?
          box.repackage
        end

        def options_spec(opts)
          opts.banner = "Usage: vagrant box repackage NAME"
        end
      end
    end
  end
end
