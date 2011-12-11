require "fileutils"
require "pathname"

require "log4r"

require "support/isolated_environment"

module Unit
  class IsolatedEnvironment < ::IsolatedEnvironment
    def create_vagrant_env
      Vagrant::Environment.new(:cwd => @workdir, :home_path => @homedir)
    end

    def vagrantfile(contents, root=nil)
      root ||= @workdir
      root.join("Vagrantfile").open("w+") do |f|
        f.write(contents)
      end
    end

    def box(name, vagrantfile_contents="")
      box_dir = boxes_dir.join(name)
      box_dir.mkpath
      vagrantfile(vagrantfile_contents, box_dir)
    end

    def boxes_dir
      dir = @homedir.join("boxes")
      dir.mkpath
      dir
    end
  end
end
