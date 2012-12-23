require "vagrant/action/builtin/confirm"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class DestroyConfirm < Vagrant::Action::Builtin::Confirm
        def initialize(app, env)
          force_key = :force_confirm_destroy
          message   = I18n.t("vagrant.commands.destroy.confirmation",
                             :name => env[:machine].name)

          super(app, env, message, force_key)
        end
      end
    end
  end
end
