module Vagrant
  module Actions
    module Box
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
