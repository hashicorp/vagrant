module VagrantPlugins
  module CommandServe
    module Types
      class Direct
        attr_accessor :args

        def initialize(arguments:)
          @args = arguments
        end
      end
    end
  end
end
