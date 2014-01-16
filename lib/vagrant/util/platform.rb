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
        def cygwin_windows_path(path, **opts)
          return path if !cygwin? && !opts[:force]

          begin
            # First try the real cygpath
            process = Subprocess.execute("cygpath", "-w", "-l", "-a", path.to_s)
            return process.stdout.chomp
          rescue Errors::CommandUnavailableWindows
            # Sometimes cygpath isn't available (msys). Instead, do what we
            # can with bash tricks.
            process = Subprocess.execute("bash", "-c", "cd #{path} && pwd")
            return process.stdout.chomp
          end
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
        def fs_real_path(path, **opts)
          path = Pathname.new(File.expand_path(path))

          if path.exist? && !fs_case_sensitive?
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
          end

          if windows?
            # Fix the drive letter to be uppercase.
            path = path.to_s
            if path[1] == ":"
              path[0] = path[0].upcase
            end

            path = Pathname.new(path)
          end

          path
        end

        # Returns a boolean noting whether the terminal supports color.
        # output.
        def terminal_supports_colors?
          return ENV.has_key?("ANSICON") || cygwin? if windows?
          true
        end

        def platform
          RbConfig::CONFIG["host_os"].downcase
        end
      end
    end
  end
end
