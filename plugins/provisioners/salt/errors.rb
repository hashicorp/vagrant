# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "vagrant"

module VagrantPlugins
  module Salt
    module Errors
      class SaltError < Vagrant::Errors::VagrantError
        error_namespace("vagrant.provisioners.salt")
      end

      class InvalidShasumError < SaltError
        error_key(:salt_invalid_shasum_error)
      end
    end
  end
end
