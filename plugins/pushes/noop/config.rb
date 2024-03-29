# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module NoopDeploy
    class Config < Vagrant.plugin("2", :config)
      def initialize
      end

      def finalize!
      end

      def validate(machine)
        errors = _detected_errors
        { "Noop push" => errors }
      end
    end
  end
end
