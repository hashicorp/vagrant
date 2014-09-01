require "optparse"

module VagrantPlugins
  module CommandVersion
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "prints current and latest Vagrant version"
      end

      def execute
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant version"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        # Output the currently installed version instantly.
        @env.ui.output(I18n.t(
          "vagrant.version_current", version: Vagrant::VERSION))
        @env.ui.machine("version-installed", Vagrant::VERSION)

        # Load the latest information
        cp = @env.checkpoint
        if !cp
          @env.ui.output("\n"+I18n.t(
            "vagrant.version_no_checkpoint"))
          return 0
        end

        latest = cp["current_version"]

        # Output latest version
        @env.ui.output(I18n.t(
          "vagrant.version_latest", version: latest))
        @env.ui.machine("version-latest", latest)

        # Determine if its a new version, and if so, output some more
        # information.
        current = Gem::Version.new(Vagrant::VERSION)
        latest  = Gem::Version.new(latest)
        if current >= latest
          @env.ui.success(" \n" + I18n.t(
            "vagrant.version_latest_installed"))
          return 0
        end

        # Out of date! Let the user know how to upgrade.
        @env.ui.output(" \n" + I18n.t(
          "vagrant.version_upgrade_howto", version: latest.to_s))

        0
      end
    end
  end
end
