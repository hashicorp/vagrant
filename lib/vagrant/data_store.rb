module Vagrant
  # The Vagrant data store is a key-value store which is persisted
  # as JSON in a local file which is specified in the initializer.
  # The data store itself is accessed via typical hash accessors: `[]`
  # and `[]=`. If a key is set to `nil`, then it is removed from the
  # datastore. The data store is only updated on disk when {commit}
  # is called on the data store itself.
  class DataStore
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path

      File.open(file_path, "r") do |f|
        @data = JSON.parse(f.read)
      end
    end

    # Returns the value associated with the `key` in the data
    # store.
    def [](key)
      @data[key]
    end

    # Sets the value in the data store.
    def []=(key, value)
      @data[key] = value
    end

    # Commits any changes to the data to disk. Even if the data
    # hasn't changed, it will be reserialized and written to disk.
    def commit
      File.open(file_path, "w") do |f|
        f.write(@data.to_json)
      end
    end
  end
end
