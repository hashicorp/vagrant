module Vagrant
  module Actions
    module Box
      # Action to destroy a box. This action is not reversible and expects
      # to be called by a {Box} object.
      class Destroy < Base
        def execute!
          logger.info "Deleting box directory..."
          FileUtils.rm_rf(@runner.directory)
        end
      end
    end
  end
end