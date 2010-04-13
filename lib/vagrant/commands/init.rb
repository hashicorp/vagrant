module Vagrant
  class Commands
    class Init < Base
      Base.subcommand "init", self
      description "Initializes current folder for Vagrant usage"

      def execute(args)
        parse_options(args) do |opts, options|
          opts.banner = "Usage: vagrant init [name]"
        end

        puts "HEY"
      end
    end
  end
end