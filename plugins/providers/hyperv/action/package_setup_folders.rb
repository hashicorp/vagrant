require "fileutils"

require_relative "../../../../lib/vagrant/action/general/package_setup_folders"

module VagrantPlugins
  module HyperV
    module Action
      class PackageSetupFolders < Vagrant::Action::General::PackageSetupFolders
        # Doing this so that we can test that the parent is properly
        # called in the unit tests.
        alias_method :general_call, :call
        def call(env)
          general_call(env)
        end
      end
    end
  end
end
