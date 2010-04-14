module Vagrant
  class Commands
    # Manages the `vagrant box` command, allowing the user to add
    # and remove boxes. This single command, given an array, determines
    # which action to take and calls the respective action method
    # (see {box_add} and {box_remove})
    class BoxCommand < Base
      Base.subcommand "box", self
      description "Box commands"

      def options_spec(opts)
        opts.banner = "Usage: vagrant box SUBCOMMAND"
      end
    end
  end
end