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
          if !Thread.current.thread_variable_get(:cacher)
            Thread.current.thread_variable_set(:cacher, Cacher.new)
          end
          @mapper.cacher = Thread.current.thread_variable_get(:cacher)
          @mapper
        end
      end
    end
  end
end
