require "rbconfig"
require "shellwords"
require "tmpdir"

require "vagrant/util/subprocess"
require "vagrant/util/powershell"

module Vagrant
  module Util
    # This class just contains some platform checking code.
    class Platform
      class << self
        def cygwin?
          return @_cygwin if defined?(@_cygwin)
          @_cygwin = -> {
            # Installer detects Cygwin
            return true if ENV["VAGRANT_DETECTED_OS"] &&
              ENV["VAGRANT_DETECTED_OS"].downcase.include?("cygwin")

            # Ruby running in Cygwin
            return true if platform.include?("cygwin")

            # Heuristic. If the path contains Cygwin, we just assume we're
            # in Cygwin. It is generally a safe bet.
            path = ENV["PATH"] || ""
            return path.include?("cygwin")
          }.call
          return @_cygwin
        end

        [:darwin, :bsd, :freebsd, :linux, :solaris].each do |type|
          define_method("#{type}?") do
            platform.include?(type.to_s)
          end
        end

        def windows?
          return @_windows if defined?(@_windows)
          @_windows = %w[mingw mswin].any? { |t| platform.include?(t) }
          return @_windows
        end

        # Checks if the user running Vagrant on Windows has administrative
        # privileges.
        #
        # From: https://support.microsoft.com/en-us/kb/243330
        # SID: S-1-5-19
        #
        # @return [Boolean]
        def windows_admin?
          return @_windows_admin if defined?(@_windows_admin)

          @_windows_admin = -> {
            ps_cmd = '(new-object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)'
            output = Vagrant::Util::PowerShell.execute_cmd(ps_cmd)
            return output == 'True'
          }.call

          return @_windows_admin
        end

        # Checks if the user running Vagrant on Windows is a member of the
        # "Hyper-V Administrators" group.
        #
        # From: https://support.microsoft.com/en-us/kb/243330
        # SID: S-1-5-32-578
        # Name: BUILTIN\Hyper-V Administrators
        #
        # @return [Boolean]
        def windows_hyperv_admin?
          return @_windows_hyperv_admin if defined?(@_windows_hyperv_admin)

          @_windows_hyperv_admin = -> {
            ps_cmd = "[System.Security.Principal.WindowsIdentity]::GetCurrent().Groups | ForEach-Object { if ($_.Value -eq 'S-1-5-32-578'){ Write-Host 'true'; break }}"
            output = Vagrant::Util::PowerShell.execute_cmd(ps_cmd)
            return output == 'true'
          }.call

          return @_windows_hyperv_admin
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
          return @_fs_case_sensitive if defined?(@_fs_case_sensitive)
          @_fs_case_sensitive = Dir.mktmpdir("vagrant-fs-case-sensitive") do |dir|
            tmp_file = File.join(dir, "FILE")
            File.open(tmp_file, "w") do |f|
              f.write("foo")
            end

            # The filesystem is case sensitive if the lowercased version
            # of the filename is NOT reported as existing.
            !File.file?(File.join(dir, "file"))
          end
          return @_fs_case_sensitive
        end

        # This expands the path and ensures proper casing of each part
        # of the path.
        def fs_real_path(path, **opts)
          path = Pathname.new(File.expand_path(path))

          if path.exist? && !fs_case_sensitive?
            # If the path contains a Windows short path, then we attempt to
            # expand. The require below is embedded here since it requires
            # windows to work.
            if windows? && path.to_s =~ /~\d(\/|\\)/
              require_relative "windows_path"
              path = Pathname.new(WindowsPath.longname(path.to_s))
            end

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
          path = path.gsub("/", "\\")

          # If the path is just a drive letter, then return that as-is
          return path + "\\" if path =~ /^[a-zA-Z]:\\?$/

          # Convert to UNC path
          "\\\\?\\" + path.gsub("/", "\\")
        end

        # Returns a boolean noting whether the terminal supports color.
        # output.
        def terminal_supports_colors?
          return @_terminal_supports_colors if defined?(@_terminal_supports_colors)
          @_terminal_supports_colors = -> {
            if windows?
              return true if ENV.key?("ANSICON")
              return true if cygwin?
              return true if ENV["TERM"] == "cygwin"
              return false
            end

            return true
          }.call
          return @_terminal_supports_colors
        end

        def platform
          return @_platform if defined?(@_platform)
          @_platform = RbConfig::CONFIG["host_os"].downcase
          return @_platform
        end

        # @private
        # Reset the cached values for platform. This is not considered a public
        # API and should only be used for testing.
        def reset!
          instance_variables.each(&method(:remove_instance_variable))
        end
      end
    end
  end
end
