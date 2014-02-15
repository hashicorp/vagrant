#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

require "json"
require "vagrant/util/which"
require "vagrant/util/subprocess"

module VagrantPlugins
  module HyperV
    module Error
      class SubprocessError < RuntimeError
        def initialize(message)
          @message = JSON.parse(message) if message
        end

        def message
          @message["error"]
        end
      end
    end
  end
end
