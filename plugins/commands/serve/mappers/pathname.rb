module VagrantPlugins
  module CommandServe
    class Mappers
      class PathnameToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Pathname)],
            output: SDK::Args::Path,
            func: method(:converter),
          )
        end

        def converter(path)
          SDK::Args::Path.new(path: path.to_s)
        end
      end

      class PathnameFromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::Args::Path)],
            output: Pathname,
            func: method(:converter),
          )
        end

        def converter(path)
          Pathname.new(path.path)
        end
      end
    end
  end
end
