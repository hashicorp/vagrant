require "fileutils"
require "pathname"

require "log4r"

require "support/isolated_environment"

module Unit
  class IsolatedEnvironment < ::IsolatedEnvironment
    def create_vagrant_env(options=nil)
      options = {
        :cwd => @workdir,
        :home_path => @homedir
      }.merge(options || {})

      Vagrant::Environment.new(options)
    end

    # This creates a file in the isolated environment. By default this file
    # will be created in the working directory of the isolated environment.
    def file(name, contents)
      @workdir.join(name).open("w+") do |f|
        f.write(contents)
      end
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
      box_dir
    end

    def boxes_dir
      dir = @homedir.join("boxes")
      dir.mkpath
      dir
    end
  end
end
