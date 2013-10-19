require "log4r"

module Vagrant
  module Action
    module Builtin
      # This action is basically a wrapper on top of provisioner runs that
      # enable plugins to hook around the provisioning itself
      class ProvisionerRun
        def initialize(app, env, provisioner)
          @app         = app
          @provisioner = provisioner
        end

        def call(env)
          @app.call(env)
          @provisioner.provision
        end
      end
    end
  end
end
