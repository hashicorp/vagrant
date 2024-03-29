# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module FTPPush
    module Errors
      class Error < Vagrant::Errors::VagrantError
        error_namespace("ftp_push.errors")
      end

      class TooManyFiles < Error
        error_key(:too_many_files)
      end
    end
  end
end
