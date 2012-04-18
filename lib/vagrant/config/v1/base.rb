module Vagrant
  module Config
    class V1
      # Base class for configuration keys. It is not required to inherit
      # from this class but this class provides useful helpers that config
      # classes may wish to use.
      class Base
        # This is a useful default to use for attributes, and the built-in
        # merge for this class will use this as a marker that a value is
        # unset (versus just being explicitly set to `nil`)
        UNSET_VALUE = Object.new
      end
    end
  end
end
