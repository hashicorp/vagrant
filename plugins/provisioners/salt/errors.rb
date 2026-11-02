# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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
