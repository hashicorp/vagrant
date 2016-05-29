require "tempfile"

module Vagrant
  module Util
    class Tempfile
      # Utility function for creating a temporary file that will persist for
      # the duration of the block and then be removed after the block finishes.
      #
      # @example
      #
      #   Tempfile.create("arch-configure-networks") do |f|
      #     f.write("network-1")
      #     f.fsync
      #     f.close
      #     do_something_with_file(f.path)
      #   end
      #
      # @example
      #
      #   Tempfile.create(["runner", "ps1"]) do |f|
      #     # f will have a suffix of ".ps1"
      #     # ...
      #   end
      #
      # @param [String, Array] name the prefix of the tempfile to create
      # @param [Hash] options a list of options
      # @param [Proc] block the block to yield the file object to
      #
      # @yield [File]
      def self.create(name, options = {})
        raise "No block given!" if !block_given?

        options = {
          binmode: true
        }.merge(options)

        # The user can specify an array where the first parameter is the prefix
        # and the last parameter is the file suffix. We want to prefix the
        # "prefix" with `vagrant-`, and this does that
        if name.is_a?(Array)
          basename = ["vagrant-#{name[0]}", name[1]]
        else
          basename = "vagrant-#{name}"
        end

        Dir::Tmpname.create(basename) do |path|
          begin
            f = File.open(path, "w+")
            f.binmode if options[:binmode]
            yield f
          ensure
            File.unlink(f.path) if File.file?(f.path)
          end
        end
      end
    end
  end
end
