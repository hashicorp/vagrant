module Vagrant
  class Commands
    class Init < Base
      def execute(args)
        parse_options(args) do |opts, options|
          opts.banner = "Usage: vagrant init [name]"
        end
      end
    end
  end
end