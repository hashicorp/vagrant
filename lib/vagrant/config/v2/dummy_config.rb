module Vagrant
  module Config
    module V2
      # This is a configuration object that can have anything done
      # to it. Anything, and it just appears to keep working.
      class DummyConfig
        def method_missing(_name, *_args, &_block)
          DummyConfig.new
        end
      end
    end
  end
end
