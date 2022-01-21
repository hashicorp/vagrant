module VagrantPlugins
  module CommandServe
    class Type
      class NamedArgument < Type
        attr_reader :name
        def initialize(name:, value:)
          @name = name
          super(value: value)
        end
      end
    end
  end
end
