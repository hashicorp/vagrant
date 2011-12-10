module Vagrant
  module Action
    module Box
      class Verify
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          begin
            @env[:ui].info I18n.t("vagrant.actions.box.verify.verifying")
            VirtualBox::Appliance.new(env["box_directory"].join("box.ovf").to_s)
          rescue Exception
            raise Errors::BoxVerificationFailed
          end

          @app.call(env)
        end
      end
    end
  end
end
