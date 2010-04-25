module Vagrant
  # Eases the processes of loading specific files then globbing
  # the rest from a specified directory.
  module GlobLoader
    # Glob requires all ruby files in a directory, optionally loading select
    # files initially (since others may depend on them).
    #
    # @param [String] dir The directory to glob
    # @param [Array<String>] initial_files Initial files (relative to `dir`)
    #   to load
    def self.glob_require(dir, initial_files=[])
      initial_files.each do |file|
        require File.expand_path(file, dir)
      end

      # Glob require the rest
      Dir[File.join(dir, "**", "*.rb")].each do |f|
        require File.expand_path(f)
      end
    end
  end
end