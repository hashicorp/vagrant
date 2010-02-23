module Vagrant
  module Actions
    module Box
      class Add < Base
        def prepare
          @runner.add_action(Download)
          @runner.add_action(Unpackage)
        end
      end
    end
  end
end