require "rubygems"
require "rubygems/config_file"
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

        # Set a custom configuration to avoid loading ~/.gemrc loads and
        # /etc/gemrc and so on.
        old_config = nil
        begin
          old_config = Gem.configuration
        rescue Psych::SyntaxError
          # Just ignore this. This means that the ".gemrc" file has
          # an invalid syntax and can't be loaded. We don't care, because
          # when we set Gem.configuration to nil later, it'll force a reload
          # if it is needed.
        end
        Gem.configuration = NilGemConfig.new

        # Clear the sources so that installation uses custom sources
        old_sources = Gem.sources
        Gem.sources = Gem.default_sources
        Gem.sources << "http://gems.hashicorp.com"

        # Use a silent UI so that we have no output
        Gem::DefaultUserInteraction.use_ui(Gem::SilentUI.new) do
          return yield
        end
      ensure
        # Restore the old GEM_* settings
        ENV["GEM_HOME"] = old_gem_home
        ENV["GEM_PATH"] = old_gem_path

        # Reset everything
        Gem.configuration = old_config
        Gem.paths   = ENV
        Gem.sources = old_sources.to_a
      end

      # This is pretty hacky but it is a custom implementatin of
      # Gem::ConfigFile so that we don't load any gemrc files.
      class NilGemConfig < Gem::ConfigFile
        def initialize
          # We _can not_ `super` here because that can really mess up
          # some other configuration state. We need to just set everything
          # directly.

          @api_keys       = {}
          @args           = []
          @backtrace      = false
          @bulk_threshold = 1000
          @hash           = {}
          @update_sources = true
          @verbose        = true
        end
      end
    end
  end
end
