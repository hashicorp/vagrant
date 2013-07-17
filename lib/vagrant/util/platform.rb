require 'rbconfig'
require 'tmpdir'

require "vagrant/util/subprocess"

module Vagrant
  module Util
    # This class just contains some platform checking code.
    class Platform
      class << self
        def cygwin?
          return true if ENV["VAGRANT_DETECTED_OS"] &&
            ENV["VAGRANT_DETECTED_OS"].downcase.include?("cygwin")

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

        # This takes any path and converts it to a full-length Windows
        # path on Windows machines in Cygwin.
        #
        # @return [String]
        def cygwin_windows_path(path)
          return path if !cygwin?

          process = Subprocess.execute("cygpath", "-w", "-l", "-a", path.to_s)
          process.stdout.chomp
        end

        # This checks if the filesystem is case sensitive. This is not a
        # 100% correct check, since it is possible that the temporary
        # directory runs a different filesystem than the root directory.
        # However, this works in many cases.
        def fs_case_sensitive?
          tmp_dir = Dir.mktmpdir("vagrant")
          tmp_file = File.join(tmp_dir, "FILE")
          File.open(tmp_file, "w") do |f|
            f.write("foo")
          end

          # The filesystem is case sensitive if the lowercased version
          # of the filename is NOT reported as existing.
          return !File.file?(File.join(tmp_dir, "file"))
        end

        # This expands the path and ensures proper casing of each part
        # of the path.
        def fs_real_path(path)
          path = Pathname.new(File.expand_path(path))
          raise "Path must exist for path expansion" if !path.exist?
          return path if fs_case_sensitive?

          # Build up all the parts of the path
          original = []
          while !path.root?
            original.unshift(path.basename.to_s)
            path = path.parent
          end

          # Traverse each part and join it into the resulting path
          original.each do |single|
            Dir.entries(path).each do |entry|
              if entry.downcase == single.downcase
                path = path.join(entry)
              end
            end
          end

          path
        end

        # Returns a boolean noting whether the terminal supports color.
        # output.
        def terminal_supports_colors?
          if windows?
            return ENV.has_key?("ANSICON") || cygwin?
          end

          true
        end

        def platform
          RbConfig::CONFIG["host_os"].downcase
        end
      end
    end
  end
end
