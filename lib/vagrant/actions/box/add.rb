module Vagrant
  module Actions
    module Box
      class Add < Base
        def initialize(runner, name, path, *args)
          super
          @name = name
          @uri = path
        end

        def prepare
          @runner.add_action(Download, @uri)
        end
      end
    end
  end
end