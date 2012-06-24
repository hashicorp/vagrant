require 'fileutils'
require 'tempfile'

# This class provides an easy way of creating a temporary
# directory and having it removed when the application exits.
class Tempdir
  attr_reader :path

  def initialize(basename="vagrant")
    @path = nil

    # Loop and attempt to create a temporary directory until
    # it succeeds.
    while @path.nil?
      file = Tempfile.new(basename)
      @path = file.path
      file.unlink

      begin
        Dir.mkdir(@path)
      rescue
        @path = nil
      end
    end

    # Setup a finalizer to delete the directory. This is the same way
    # that Tempfile and friends do this...
    @cleanup_proc = lambda do
      FileUtils.rm_rf(@path) if File.directory?(@path)
    end

    ObjectSpace.define_finalizer(self, @cleanup_proc)
  end

  # This deletes the temporary directory.
  def unlink
    # Delete the directory
    @cleanup_proc.call

    # Undefine the finalizer since we're all cleaned up
    ObjectSpace.undefine_finalizer(self)
  end
end
