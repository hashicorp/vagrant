require "vagrant/action/builtin/confirm"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class DestroyConfirm < Vagrant::Action::Builtin::Confirm
        def initialize(app, env)
          message = I18n.t("vagrant.commands.destroy.confirmation",
                           :name => env[:machine].name)

          super(app, env, message)
        end
      end
    end
  end
end
