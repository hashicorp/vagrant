require "rubygems"
require "rubygems/gem_runner"

module Vagrant
  module Command
    class Gem < Base
      def execute
        # We just proxy the arguments onto a real RubyGems command
        # but change `GEM_HOME` so that the gems are installed into
        # our own private gem folder.
        ENV["GEM_HOME"] = @env.gems_path.to_s
        ::Gem.clear_paths
        ::Gem::GemRunner.new.run(@argv.dup)
      end
    end
  end
end
