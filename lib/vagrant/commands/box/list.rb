module Vagrant
  class Commands
    # Lists all added boxes
    module Box
      class List < BoxCommand
        BoxCommand.subcommand "list", self
        description "List all installed boxes"

        def execute(args=[])
          boxes = Vagrant::Box.all(env).sort

          wrap_output do
            if !boxes.empty?
              puts "Installed Vagrant Boxes:\n\n"
              boxes.each do |box|
                puts box
              end
            else
              puts "No Vagrant Boxes Added!"
            end
          end
        end

        def options_spec(opts)
          opts.banner = "Usage: vagrant box list"
        end
      end
    end
  end
end