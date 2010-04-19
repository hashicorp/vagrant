module Vagrant
  module Actions
    module Box
      # A meta-action which adds a box by downloading and unpackaging it.
      # This action downloads and unpackages a box with a given URI. This
      # is a _meta action_, meaning it simply adds more actions to the
      # action chain, and those actions do the work.
      #
      # This is the action called by {Box#add}.
      class Add < Base
        def prepare
          if File.exists?(@runner.directory)
            raise ActionException.new(:box_add_already_exists, :box_name => @runner.name)
          end

          @runner.add_action(Download)
          @runner.add_action(Unpackage)
          @runner.add_action(Verify)
        end
      end
    end
  end
end
