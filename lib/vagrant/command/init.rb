module Vagrant
  module Command
    class InitCommand < Base
      argument :box_name, :type => :string, :optional => true, :default => "base"
      argument :box_url, :type => :string, :optional => true
      source_root File.expand_path("templates/commands/init", Vagrant.source_root)
      register "init [box_name] [box_url]", "Initializes the current folder for Vagrant usage"

      def execute
        template "Vagrantfile.erb", env.cwd.join("Vagrantfile")
      end
    end
  end
end
