module VagrantPlugins
  module CommandServe
    class Type
      class Boolean < Type

        def initialize(value:)
          super(value: !!value)
        end
      end
    end
  end
end
