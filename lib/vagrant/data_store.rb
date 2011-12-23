require 'pathname'

require 'log4r'

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
      @logger    = Log4r::Logger.new("vagrant::datastore")
      @logger.info("Created: #{file_path}")

      @file_path = Pathname.new(file_path)

      if @file_path.exist?
        raise Errors::DotfileIsDirectory if @file_path.directory?

        begin
          merge!(JSON.parse(@file_path.read))
        rescue JSON::ParserError
          # Ignore if the data is invalid in the file.
          @logger.error("Data store contained invalid JSON. Ignoring.")
        end
      end
    end

    # Commits any changes to the data to disk. Even if the data
    # hasn't changed, it will be reserialized and written to disk.
    def commit
      clean_nil_and_empties

      if empty?
        # Delete the file since an empty data store is not useful
        @logger.info("Deleting data store since we're empty: #{@file_path}")
        @file_path.delete if @file_path.exist?
      else
        @logger.info("Committing data to data store: #{@file_path}")

        @file_path.open("w") do |f|
          f.write(to_json)
          f.fsync
        end
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
