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

    # Creates a fake box to exist in this environment.
    #
    # @param [String] name Name of the box
    # @param [Symbol] provider Provider the box was built for.
    # @return [Pathname] Path to the box directory.
    def box2(name, provider)
      # Make the box directory
      box_dir = boxes_dir.join(name, provider.to_s)
      box_dir.mkpath

      # Create a metadata.json file
      box_metadata_file = box_dir.join("metadata.json")
      box_metadata_file.open("w") do |f|
        f.write("")
      end

      # Return the box directory
      box_dir
    end

    def boxes_dir
      dir = @homedir.join("boxes")
      dir.mkpath
      dir
    end
  end
end
