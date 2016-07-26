require_relative "../../../../lib/vagrant/action/general/package"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class Package < Vagrant::Action::General::Package
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
