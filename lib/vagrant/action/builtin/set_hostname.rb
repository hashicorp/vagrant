require "log4r"

module Vagrant
  module Action
    module Builtin
      # This middleware sets the hostname of the guest according to the
      # "vm.hostname" configuration parameter if it is set. This middleware
      # should be placed such that the after the @app.call, a booted machine
      # is available (this generally means BEFORE the boot middleware).
      class SetHostname
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @app.call(env)

          hostname = env[:machine].config.vm.hostname
          if !hostname.nil?
            env[:ui].info I18n.t("vagrant.actions.vm.hostname.setting")
            env[:machine].guest.capability(:change_host_name, hostname)
          end
        end
      end
    end
  end
end
