module Vagrant
  module Action
    module Box
      class Verify
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          @env[:ui].info I18n.t("vagrant.actions.box.verify.verifying")

          driver = Driver::VirtualBox.new(nil)
          if !driver.verify_image(env["box_directory"].join("box.ovf").to_s)
            raise Errors::BoxVerificationFailed
          end

          @app.call(env)
        end
      end
    end
  end
end
