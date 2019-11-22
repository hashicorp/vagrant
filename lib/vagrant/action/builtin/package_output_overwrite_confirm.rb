require_relative "confirm"

module Vagrant
  module Action
    module Builtin
      class PackageOutputOverwriteConfirm < Confirm
        def initialize(app, env)
          force_key = "package.force_output_overwrite"
          message = I18n.t("vagrant.actions.general.package.output_exists.overwrite_confirmation",
                           name: env["package.output"])

          super(app, env, message, force_key, allowed: %w(y n Y N))
        end

        def call(env)
          output = File.expand_path(env["package.output"], Dir.pwd)

          if File.exist?(output)
            super
          else
            env[:result] = true
            @app.call(env)
          end
        end
      end
    end
  end
end
