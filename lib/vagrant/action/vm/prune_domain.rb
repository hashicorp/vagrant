module Vagrant
  module Action
    module VM
      class PruneDOMAIN
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:host]
            valid_ids = env[:vm].driver.read_vms
            # remove domain from /etc/hosts
            system("sudo sed -e '/^# VAGRANT-BEGIN/,/^# VAGRANT-END/ d' -ibak /etc/hosts")
          end

          @app.call(env)
        end
      end
    end
  end
end
