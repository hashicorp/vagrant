module Vagrant
  # The Vagrant data store is a key-value store which is persisted
  # as JSON in a local file which is specified in the initializer.
  # The data store itself is accessed via typical hash accessors: `[]`
  # and `[]=`. If a key is set to `nil`, then it is removed from the
  # datastore. The data store is only updated on disk when {#commit}
  # is called on the data store itself.
  #
  # The data store is a hash with indifferent access, meaning that
  # while all keys are persisted as strings in the JSON, you can access
  # them back as either symbols or strings. Note that this is only true
  # for the top-level data store. As soon as you set a hash inside the
  # data store, unless you explicitly use a {Util::HashWithIndifferentAccess},
  # it will be a regular hash.
  class DataStore < Util::HashWithIndifferentAccess
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
      return if !file_path

      raise Errors::DotfileIsDirectory if File.directory?(file_path)

      if File.exist?(file_path)
        File.open(file_path, "r") do |f|
          begin
            merge!(JSON.parse(f.read))
          rescue JSON::ParserError
            # Ignore if the data is invalid in the file.
            # TODO: Log here.
          end
        end
      end
    end

    # Commits any changes to the data to disk. Even if the data
    # hasn't changed, it will be reserialized and written to disk.
    def commit
      return if !file_path

      clean_nil_and_empties

      if empty?
        # Delete the file since an empty data store is not useful
        File.delete(file_path) if File.file?(file_path)
      else
        File.open(file_path, "w") { |f| f.write(to_json) }
      end
    end

    protected

    # Removes the "nil" and "empty?" values from the hash (children
    # included) so that the final output JSON is cleaner.
    def clean_nil_and_empties(hash=self)
      # Clean depth first
      hash.each do |k, v|
        clean_nil_and_empties(v) if v.is_a?(Hash)
      end

      # Clean ourselves, knowing that any children have already been
      # cleaned up
      bad_keys = hash.inject([]) do |acc, data|
        k,v = data
        acc.push(k) if v.nil?
        acc.push(k) if v.respond_to?(:empty?) && v.empty?
        acc
      end

      bad_keys.each do |key|
        hash.delete(key)
      end
    end
  end
end
