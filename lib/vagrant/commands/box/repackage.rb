module Vagrant
  class Commands
    module Box
      # Repackage a box which has been added.
      class Repackage < BoxCommand
        BoxCommand.subcommand "repackage", self
        description "Repackages a box which has already been added."

        def execute(args=[])
          args = parse_options(args)
          return show_help if args.length != 1

          box = Vagrant::Box.find(env, args.first)
          return error_and_exit(:box_repackage_doesnt_exist) if box.nil?
          box.repackage(options)
        end

        def options_spec(opts)
          opts.banner = "Usage: vagrant box repackage NAME [--output FILENAME] [--include FILES]"

          options["package.output"] = nil
          options["package.include"] = []

          opts.on("--include x,y,z", Array, "List of files to include in the package") do |v|
            options["package.include"] = v
          end

          opts.on("-o", "--output FILE", "File to save the package as.") do |v|
            options["package.output"] = v
          end
        end
      end
    end
  end
end
