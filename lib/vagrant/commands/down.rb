module Vagrant
  class Commands
    # `vagrant down` is now `vagrant destroy`
    class Down < Base
      Base.subcommand "down", self

      def execute(args=[])
        error_and_exit(:command_deprecation_down)
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant down"
      end
    end
  end
end