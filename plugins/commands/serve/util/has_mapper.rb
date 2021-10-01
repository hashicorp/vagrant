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
          # TODO(spox): enable this when future is present
          # @mapper.cacher = @cacher
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
