# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    module Util
      # Creates a new logger instance and provides method
      # to access it
      module HasLogger
        def logger
          if !@logger
            @logger = Log4r::Logger.new(self.class.name.to_s.downcase)
          end
          @logger
        end
      end
    end
  end
end
