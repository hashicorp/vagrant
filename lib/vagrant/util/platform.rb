require 'rbconfig'
require 'shellwords'
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

        # Checks if the user running Vagrant on Windows has administrative
        # privileges.
        #
        # @return [Boolean]
        def windows_admin?
          # We lazily-load this because it is only available on Windows
          require 'win32/registry'

          # Verify that we have administrative privileges. The odd method of
          # detecting this is based on this StackOverflow question:
          #
          # http://stackoverflow.com/questions/560366/
          #   detect-if-running-with-administrator-privileges-under-windows-xp
          begin
            Win32::Registry::HKEY_USERS.open("S-1-5-19") {}
            return true
          rescue Win32::Registry::Error
            return false
          end
        end

        # This takes any path and converts it from a Windows path to a
        # Cygwin or msys style path.
        #
        # @param [String] path
        # @return [String]
        def cygwin_path(path)
          if cygwin?
            begin
              # First try the real cygpath
              process = Subprocess.execute("cygpath", "-u", "-a", path.to_s)
              return process.stdout.chomp
            rescue Errors::CommandUnavailableWindows
            end
          end

          # Sometimes cygpath isn't available (msys). Instead, do what we
          # can with bash tricks.
          process = Subprocess.execute(
            "bash",
            "--noprofile",
            "--norc",
            "-c", "cd #{Shellwords.escape(path)} && pwd")
          return process.stdout.chomp
        end

        # This takes any path and converts it to a full-length Windows
        # path on Windows machines in Cygwin.
        #
        # @return [String]
        def cygwin_windows_path(path)
          return path if !cygwin?

          # Replace all "\" with "/", otherwise cygpath doesn't work.
          path = path.gsub("\\", "/")

          # Call out to cygpath and gather the result
          process = Subprocess.execute("cygpath", "-w", "-l", "-a", path.to_s)
          return process.stdout.chomp
        end

        # This checks if the filesystem is case sensitive. This is not a
        # 100% correct check, since it is possible that the temporary
        # directory runs a different filesystem than the root directory.
        # However, this works in many cases.
        def fs_case_sensitive?
          Dir.mktmpdir("vagrant") do |tmp_dir|
            tmp_file = File.join(tmp_dir, "FILE")
            File.open(tmp_file, "w") do |f|
              f.write("foo")
            end

            # The filesystem is case sensitive if the lowercased version
            # of the filename is NOT reported as existing.
            !File.file?(File.join(tmp_dir, "file"))
          end
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
                if entry.downcase == single.encode('filesystem').downcase
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

        # Converts a given path to UNC format by adding a prefix and converting slashes.
        # @param [String] path Path to convert to UNC for Windows
        # @return [String]
        def windows_unc_path(path)
          "\\\\?\\" + path.gsub("/", "\\")
        end

        # Returns a boolean noting whether the terminal supports color.
        # output.
        def terminal_supports_colors?
          if windows?
            return true if ENV.key?("ANSICON")
            return true if cygwin?
            return true if ENV["TERM"] == "cygwin"
            return false
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
