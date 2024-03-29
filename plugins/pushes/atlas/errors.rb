# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module AtlasPush
    module Errors
      class Error < Vagrant::Errors::VagrantError
        error_namespace("atlas_push.errors")
      end

      class UploaderNotFound < Error
        error_key(:uploader_not_found)
      end
    end
  end
end
