require "log4r"

require_relative "package_setup_files"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class SetupPackageFiles < PackageSetupFiles
        def initialize(*)
          @logger = Log4r::Logger.new("vagrant::plugins::virtualbox::setup_package_files")
          @logger.warn { "SetupPackageFiles has been renamed to PackageSetupFiles" }
          super
        end
      end
    end
  end
end
