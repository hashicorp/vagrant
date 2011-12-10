require 'vagrant/action/general/package'

module Vagrant
  module Action
    module VM
      # A subclass of {General::Package} which simply makes sure that
      # the package directory is set to the directory which the VM
      # was exported to.
      class Package < General::Package
        # Doing this so that we can test that the parent is properly
        # called in the unit tests.
        alias_method :general_call, :call
        def call(env)
          # Just match up a couple environmental variables so that
          # the superclass will do the right thing. Then, call the
          # superclass
          env["package.directory"] = env["export.temp_dir"]
          general_call(env)
        end
      end
    end
  end
end
