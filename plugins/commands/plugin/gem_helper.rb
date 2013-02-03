require "rubygems"
require "rubygems/gem_runner"

require "log4r"

module VagrantPlugins
  module CommandPlugin
    # This class provides methods to help with calling out to the
    # `gem` command but using the RubyGems API.
    class GemHelper
      def initialize(gem_home)
        @gem_home = gem_home.to_s
        @logger   = Log4r::Logger.new("vagrant::plugins::plugincommand::gemhelper")
      end

      # This will yield the given block with the proper ENV setup so
      # that RubyGems only sees the gems in the Vagrant-managed gem
      # path.
      def with_environment
        old_gem_home = ENV["GEM_HOME"]
        old_gem_path = ENV["GEM_PATH"]
        ENV["GEM_HOME"] = @gem_home
        ENV["GEM_PATH"] = @gem_home
        @logger.debug("Set GEM_* to: #{ENV["GEM_HOME"]}")

        # Clear paths so that it reads the new GEM_HOME setting
        Gem.paths = ENV

        # Use a silent UI so that we have no output
        Gem::DefaultUserInteraction.use_ui(Gem::SilentUI.new) do
          return yield
        end
      ensure
        # Restore the old GEM_* settings
        ENV["GEM_HOME"] = old_gem_home
        ENV["GEM_PATH"] = old_gem_path

        # Reset everything
        Gem.paths = ENV
      end
    end
  end
end
