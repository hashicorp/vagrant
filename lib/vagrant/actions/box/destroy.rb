module Vagrant
  module Actions
    module Box
      class Destroy < Base
        def execute!
          logger.info "Deleting box directory..."
          FileUtils.rm_rf(@runner.directory)
        end
      end
    end
  end
end