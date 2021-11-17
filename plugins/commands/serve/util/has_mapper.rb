module VagrantPlugins
  module CommandServe
    module Util
      # Adds mapper initialization and will include
      module HasMapper
        def mapper
          if !Thread.current.thread_variable_get(:cacher)
            Thread.current.thread_variable_set(:cacher, Cacher.new)
          end
          @mapper.cacher = Thread.current.thread_variable_get(:cacher)
          @mapper
        end

        def initialize(*args, **opts, &block)
          @mapper = Mappers.new
          if respond_to?(:broker)
            @mapper.add_argument(broker)
          end

          sup = self.method(:initialize).super_method
          if sup.parameters.empty?
            super()
          elsif !opts.empty? && sup.parameters.detect{ |type, _| type == :keyreq || type == :keyrest }
            super
          else
            super(*args, &block)
          end
        end
      end
    end
  end
end
