module Vagrant
  # The Vagrant data store is a key-value store which is persisted
  # as JSON in a local file which is specified in the initializer.
  # The data store itself is accessed via typical hash accessors: `[]`
  # and `[]=`. If a key is set to `nil`, then it is removed from the
  # datastore. The data store is only updated on disk when {commit}
  # is called on the data store itself.
  class DataStore < Hash
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
      return if !file_path

      File.open(file_path, "r") do |f|
        merge!(JSON.parse(f.read))
      end
    rescue Errno::ENOENT
      clear
    end

    # Commits any changes to the data to disk. Even if the data
    # hasn't changed, it will be reserialized and written to disk.
    def commit
      return if !file_path

      File.open(file_path, "w") do |f|
        f.write(to_json)
      end
    end
  end
end
