require 'rbconfig'

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
