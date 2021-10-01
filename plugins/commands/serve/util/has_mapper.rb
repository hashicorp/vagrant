module VagrantPlugins
  module CommandServe
    module Util
      # Adds mapper initialization and will include
      module HasMapper
        def mapper
          @mapper
        end

        def initialize(*args, **opts, &block)
          @cacher = Cacher.new
          @mapper = Mappers.new
          @mapper.cacher = @cacher
          if respond_to?(:broker)
            @mapper.add_argument(broker)
          end

          if self.method(:initialize).super_method.parameters.empty?
            super()
          else
            super
          end
        end
      end
    end
  end
end
