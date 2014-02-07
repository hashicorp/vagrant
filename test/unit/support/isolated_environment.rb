require "fileutils"
require "pathname"
require "tempfile"
require "tmpdir"

require "json"
require "log4r"

require "vagrant/util/platform"
require "vagrant/util/subprocess"

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
      # Create the box directory
      box_dir = boxes_dir.join(name)
      box_dir.mkpath

      # Create the "box.ovf" file because that is how Vagrant heuristically
      # determines a box is a V1 box.
      box_dir.join("box.ovf").open("w") { |f| f.write("") }

      # Populate the vagrantfile
      vagrantfile(vagrantfile_contents, box_dir)

      # Return the directory
      box_dir
    end

    # Create an alias because "box" makes a V1 box, so "box1"
    alias :box1 :box

    # Creates a fake box to exist in this environment.
    #
    # @param [String] name Name of the box
    # @param [Symbol] provider Provider the box was built for.
    # @return [Pathname] Path to the box directory.
    def box2(name, provider, options=nil)
      # Default options
      options = {
        :vagrantfile => ""
      }.merge(options || {})

      # Make the box directory
      box_dir = boxes_dir.join(name, provider.to_s)
      box_dir.mkpath

      # Create a metadata.json file
      box_metadata_file = box_dir.join("metadata.json")
      box_metadata_file.open("w") do |f|
        f.write(JSON.generate({
          :provider => provider.to_s
        }))
      end

      # Create a Vagrantfile
      box_vagrantfile = box_dir.join("Vagrantfile")
      box_vagrantfile.open("w") do |f|
        f.write(options[:vagrantfile])
      end

      # Return the box directory
      box_dir
    end

    # Creates a fake box to exist in this environment according
    # to the "gen-3" box format.
    #
    # @param [String] name
    # @param [String] version
    # @param [String] provider
    # @return [Pathname]
    def box3(name, version, provider, **opts)
      # Create the directory for the box
      box_dir = boxes_dir.join(name, version, provider.to_s)
      box_dir.mkpath

      # Create the metadata.json for it
      box_metadata_file = box_dir.join("metadata.json")
      box_metadata_file.open("w") do |f|
        f.write(JSON.generate({
          :provider => provider.to_s
        }))
      end

      # Create a Vagrantfile
      if opts[:vagrantfile]
        box_vagrantfile = box_dir.join("Vagrantfile")
        box_vagrantfile.open("w") do |f|
          f.write(opts[:vagrantfile])
        end
      end

      # Create the metadata URL
      if opts[:metadata_url]
        boxes_dir.join(name, "metadata_url").open("w") do |f|
          f.write(opts[:metadata_url])
        end
      end

      box_dir
    end

    # This creates a "box" file that is a valid V1 box.
    #
    # @return [Pathname] Path to the newly created box.
    def box1_file
      # Create a temporary directory to store our data we will tar up
      td_source = Dir.mktmpdir
      td_dest   = Dir.mktmpdir

      # Store the temporary directory so it is not deleted until
      # this instance is garbage collected.
      @_box2_file_temp ||= []
      @_box2_file_temp << td_dest

      # The source as a Pathname, which is easier to work with
      source = Pathname.new(td_source)

      # The destination file
      result = Pathname.new(td_dest).join("temporary.box")

      # Put a "box.ovf" in there.
      source.join("box.ovf").open("w") do |f|
        f.write("FOO!")
      end

      Dir.chdir(source) do
        # Find all the files in our current directory and tar it up!
        files = Dir.glob(File.join(".", "**", "*"))

        # Package!
        Vagrant::Util::Subprocess.execute("bsdtar", "-czf", result.to_s, *files)
      end

      # Resulting box
      result
    end

    # This creates a "box" file with the given provider.
    #
    # @param [Symbol] provider Provider for the box.
    # @return [Pathname] Path to the newly created box.
    def box2_file(provider, options=nil)
      options ||= {}

      # This is the metadata we want to store in our file
      metadata = {
        "type"     => "v2_box",
        "provider" => provider
      }.merge(options[:metadata] || {})

      # Create a temporary directory to store our data we will tar up
      td_source = Dir.mktmpdir
      td_dest   = Dir.mktmpdir

      # Store the temporary directory so it is not deleted until
      # this instance is garbage collected.
      @_box2_file_temp ||= []
      @_box2_file_temp << td_dest

      # The source as a Pathname, which is easier to work with
      source = Pathname.new(td_source)

      # The destination file
      result = Pathname.new(td_dest).join("temporary.box")

      # Put the metadata.json in here.
      source.join("metadata.json").open("w") do |f|
        f.write(JSON.generate(metadata))
      end

      Dir.chdir(source) do
        # Find all the files in our current directory and tar it up!
        files = Dir.glob(File.join(".", "**", "*"))

        # Package!
        Vagrant::Util::Subprocess.execute("bsdtar", "-czf", result.to_s, *files)
      end

      # Resulting box
      result
    end

    def boxes_dir
      dir = @homedir.join("boxes")
      dir.mkpath
      dir
    end
  end
end
