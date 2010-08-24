module Vagrant
  module Command
    class InitCommand < Base
      desc "Initializes the current folder for Vagrant usage"
      argument :box_name, :type => :string, :optional => true, :default => "base"
      argument :box_url, :type => :string, :optional => true
      source_root File.expand_path("templates/commands/init", Vagrant.source_root)
      register "init [box_name] [box_url]"

      def execute
        template "Vagrantfile.erb", "Vagrantfile"
      end
    end
  end
end
