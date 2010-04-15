module Vagrant
  module Util
    # This class just contains some platform checking code.
    class Platform
      class <<self
        def leopard?
          RUBY_PLATFORM.downcase.include?("darwin9")
        end
      end
    end
  end
end