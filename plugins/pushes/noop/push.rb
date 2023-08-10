# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module NoopDeploy
    class Push < Vagrant.plugin("2", :push)
      def push
        puts "pushed"
      end
    end
  end
end
