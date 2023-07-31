# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    module Util
      # Adds mapper initialization and will include
      module HasMapper
        def mapper
          return @mapper if @mapper
          @mapper = Mappers.new
          if respond_to?(:broker) && broker
            @mapper.add_argument(broker)
          end
          if respond_to?(:cacher) && cacher
            @mapper.add_argument(cacher)
          end
          @mapper
        end
      end
    end
  end
end
