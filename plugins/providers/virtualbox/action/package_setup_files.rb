require_relative "../../../../lib/vagrant/action/general/package_setup_files"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class PackageSetupFiles < Vagrant::Action::General::PackageSetupFiles
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
