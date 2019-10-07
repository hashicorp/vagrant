module Vagrant
  module Config
    module V2
      # This is a configuration object that can have anything done
      # to it. Anything, and it just appears to keep working.
      class DummyConfig
        def method_missing(name, *args, &block)
          DummyConfig.new
        end

        def to_json(*_)
          "null"
        end
      end
    end
  end
end
