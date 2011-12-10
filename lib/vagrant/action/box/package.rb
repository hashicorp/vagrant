require 'vagrant/action/general/package'

module Vagrant
  module Action
    module Box
      # Packages a box which has already been unpackaged (such as
      # for the `vagrant box repackage` command) by leveraging the
      # general packager middleware.
      class Package < General::Package
        # Alias instead of calling super for testability
        alias_method :general_call, :call
        def call(env)
          env["package.directory"] = env["box_directory"]
          general_call(env)
        end
      end
    end
  end
end
