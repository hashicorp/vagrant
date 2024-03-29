# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module HyperV
    module Action
      class MessageWillNotDestroy
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t("vagrant.commands.destroy.will_not_destroy",
                              name: env[:machine].name)
          @app.call(env)
        end
      end
    end
  end
end
