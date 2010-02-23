module Vagrant
  module Actions
    module Box
      class Add < Base
        def prepare
          @runner.add_action(Download)
        end
      end
    end
  end
end