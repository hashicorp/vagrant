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

      def cli(argv)
        # Initialize the UI to use for RubyGems. This allows us to capture
        # the stdout/stderr without actually going to the real STDOUT/STDERR.
        # The final "false" here tells RubyGems we're not a TTY, so don't
        # ask us things.
        gem_ui = Gem::StreamUI.new(StringIO.new, StringIO.new, StringIO.new, false)

        # Set the GEM_HOME so that it is installed into our local gems path
        old_gem_home = ENV["GEM_HOME"]
        ENV["GEM_HOME"] = @gem_home
        @logger.debug("Set GEM_HOME to: #{ENV["GEM_HOME"]}")
        @logger.info("Calling gem with argv: #{argv.inspect}")
        Gem.clear_paths
        Gem::DefaultUserInteraction.use_ui(gem_ui) do
          Gem::GemRunner.new.run(argv)
        end
      rescue Gem::SystemExitException => e
        # This means that something forced an exit within RubyGems.
        # We capture this to check whether it succeeded or not by
        # checking the "exit_code"
        raise Vagrant::Errors::PluginGemError, :output => gem_ui.errs.string.chomp if e != 0
      ensure
        # Restore the old GEM_HOME
        ENV["GEM_HOME"] = old_gem_home

        # Log the output properly
        @logger.debug("Gem STDOUT: #{gem_ui.outs.string}")
        @logger.debug("Gem STDERR: #{gem_ui.errs.string}")
      end
    end
  end
end
