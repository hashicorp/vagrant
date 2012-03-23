module Vagrant
  module Action
    module VM
      # This middleware enforces some sane defaults on the virtualbox
      # VM which help with performance, stability, and in some cases
      # behavior.
      class SaneDefaults
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Enable the host IO cache on the sata controller. Note that
          # if this fails then its not a big deal, so we don't raise any
          # errors. The Host IO cache vastly improves disk IO performance
          # for VMs.
          command = [
            "storagectl", env[:vm].uuid,
            "--name", "SATA Controller",
            "--hostiocache", "on"
          ]
          env[:vm].driver.execute_command(command)

          # Enable the DNS proxy while in NAT mode.  This shields the guest
          # VM from external DNS changs on the host machine.
          command = [
            "modifyvm", env[:vm].uuid,
            "--natdnsproxy1", "on"
          ]
          env[:vm].driver.execute_command(command)

          @app.call(env)
        end
      end
    end
  end
end
