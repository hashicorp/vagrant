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
            raise ActionException.new("A box with the name '#{@runner.name}' already exists, please use another name or use `vagrant box remove #{@runner.name}`")
          end

          @runner.add_action(Download)
          @runner.add_action(Unpackage)
        end
      end
    end
  end
end
