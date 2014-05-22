require_relative "confirm"

module Vagrant
  module Action
    module Builtin
      # This class asks the user to confirm the destruction of a machine
      # that Vagrant manages. This is provided as a built-in on top of
      # {Confirm} because it sets up the proper keys and such so that
      # `vagrant destroy -f` works properly.
      class DestroyConfirm < Confirm
        def initialize(app, env)
          force_key = :force_confirm_destroy
          message   = I18n.t("vagrant.commands.destroy.confirmation",
                             name: env[:machine].name)

          super(app, env, message, force_key, allowed: ["y", "n", "Y", "N"])
        end
      end
    end
  end
end
