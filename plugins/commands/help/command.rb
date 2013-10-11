require 'optparse'

module VagrantPlugins
  module CommandHelp
    class Command < Vagrant.plugin("2", :command)
      def execute
        return @env.cli([]) if @argv.empty?
        @env.cli([@argv[0], "-h"])
      end
    end
  end
end
