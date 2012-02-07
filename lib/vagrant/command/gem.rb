require "rubygems"
require "rubygems/gem_runner"

module Vagrant
  module Command
    class Gem < Base
      def execute
        # Bundler sets up its own custom gem load paths such that our
        # own gems are never loaded. Therefore, give an error if a user
        # tries to install gems while within a Bundler-managed environment.
        if defined?(Bundler)
          require 'bundler/shared_helpers'
          if Bundler::SharedHelpers.in_bundle?
            raise Errors::GemCommandInBundler
          end
        end

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
