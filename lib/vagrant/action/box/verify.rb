module Vagrant
  class Action
    module Box
      class Verify
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          begin
            env.ui.info I18n.t("vagrant.actions.box.verify.verifying")
            VirtualBox::Appliance.new(env["box"].ovf_file.to_s)
          rescue Exception
            raise Errors::BoxVerificationFailed.new
          end

          @app.call(env)
        end
      end
    end
  end
end
