require 'pathname'

module Vagrant
  module Util
    class Directory
      # Check if directory has any new updates
      #
      # @param [Pathname, String] Path to directory
      # @param [Time] time to compare to eg. has any file in dir_path
      #               changed since this time
      # @return [Boolean]
      def self.directory_changed?(dir_path, threshold_time)
        Dir.glob(Pathname.new(dir_path).join("**", "*")).any? do |path|
          Pathname.new(path).mtime > threshold_time
        end
      end
    end
  end
end
