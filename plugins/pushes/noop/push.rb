# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module NoopDeploy
    class Push < Vagrant.plugin("2", :push)
      def push
        puts "pushed"
      end
    end
  end
end
