require 'rbconfig'
require 'tempfile'

require "vagrant/util/subprocess"

module Vagrant
  module Util
    # This class just contains some platform checking code.
    class Platform
      class << self
        def tiger?
          platform.include?("darwin8")
        end

        def leopard?
          platform.include?("darwin9")
        end

        def cygwin?
          platform.include?("cygwin")
        end

        [:darwin, :bsd, :freebsd, :linux, :solaris].each do |type|
          define_method("#{type}?") do
            platform.include?(type.to_s)
          end
        end

        def windows?
          %W[mingw mswin].each do |text|
            return true if platform.include?(text)
          end

          false
        end

        # Returns boolean noting whether this is a 64-bit CPU. This
        # is not 100% accurate and there could easily be false negatives.
        #
        # @return [Boolean]
        def bit64?
          ["x86_64", "amd64"].include?(RbConfig::CONFIG["host_cpu"])
        end

        # Returns boolean noting whether this is a 32-bit CPU. This
        # can easily throw false positives since it relies on {#bit64?}.
        #
        # @return [Boolean]
        def bit32?
          !bit64?
        end

        # This takes as input a path as a string and converts it into
        # a platform-friendly version of the path. This is most important
        # when using the path in shell environments with Cygwin.
        #
        # @param [String] path
        # @return [String]
        def platform_path(path)
          return path if !cygwin?

          process = Subprocess.execute("cygpath", "-u", path.to_s)
          process.stdout.chomp
        end

        # Returns a boolean noting whether the terminal supports color.
        # output.
        def terminal_supports_colors?
          if windows?
            return ENV.has_key?("ANSICON")
          end

          true
        end

        def tar_file_options
          # create, write only, fail if the file exists, binary if windows
          File::WRONLY | File::EXCL | File::CREAT | (windows? ? File::BINARY : 0)
        end

        def platform
          RbConfig::CONFIG["host_os"].downcase
        end
      end
    end
  end
end
