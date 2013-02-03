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

      # This executes the `gem` command with the given arguments. Under
      # the covers this is actually using the RubyGems API directly,
      # instead of shelling out, which allows for more fine-grained control.
      #
      # @param [Array<String>] argv The arguments to send to the `gem` command.
      def cli(argv)
        # Initialize the UI to use for RubyGems. This allows us to capture
        # the stdout/stderr without actually going to the real STDOUT/STDERR.
        # The final "false" here tells RubyGems we're not a TTY, so don't
        # ask us things.
        gem_ui = Gem::StreamUI.new(StringIO.new, StringIO.new, StringIO.new, false)

        # Set the GEM_HOME so that it is installed into our local gems path
        with_environment do
          @logger.info("Calling gem with argv: #{argv.inspect}")
          Gem::DefaultUserInteraction.use_ui(gem_ui) do
            Gem::GemRunner.new.run(argv)
          end
        end
      rescue Gem::SystemExitException => e
        # This means that something forced an exit within RubyGems.
        # We capture this to check whether it succeeded or not by
        # checking the "exit_code"
        raise Vagrant::Errors::PluginGemError,
          :output => gem_ui.errs.string.chomp if e.exit_code != 0
      ensure
        # Log the output properly
        @logger.debug("Gem STDOUT: #{gem_ui.outs.string}")
        @logger.debug("Gem STDERR: #{gem_ui.errs.string}")
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
