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
            process = Subprocess.execute(
              "bash",
              "--noprofile",
              "--norc",
              "-c", "cd #{path} && pwd")
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
          if windows?
            return true if ENV.has_key?("ANSICON")
            return true if cygwin?
            return true if ENV["TERM"] == "cygwin"
            return false
          end

          true
        end

        def platform
          @platform ||= RbConfig::CONFIG["host_os"].downcase
        end

        def max_cpus
          # Taken from https://github.com/grosser/parallel/blob/master/lib/parallel.rb#L136
          @processor_count ||= begin
            if platform =~ /mingw|mswin/
              require 'win32ole'
              result = WIN32OLE.connect("winmgmts://").ExecQuery(
                        "select NumberOfLogicalProcessors from Win32_Processor")
              result.to_enum.collect(&:NumberOfLogicalProcessors).reduce(:+)
            elsif File.readable?("/proc/cpuinfo")
              ::IO.read("/proc/cpuinfo").scan(/^processor/).size
            elsif File.executable?("/usr/bin/hwprefs")
              ::IO.popen("/usr/bin/hwprefs thread_count").read.to_i
            elsif File.executable?("/usr/sbin/psrinfo")
              ::IO.popen("/usr/sbin/psrinfo").read.scan(/^.*on-*line/).size
            elsif File.executable?("/usr/sbin/ioscan")
              ::IO.popen("/usr/sbin/ioscan -kC processor") do |out|
                out.read.scan(/^.*processor/).size
              end
            elsif File.executable?("/usr/sbin/pmcycles")
              ::IO.popen("/usr/sbin/pmcycles -m").read.count("\n")
            elsif File.executable?("/usr/sbin/lsdev")
              ::IO.popen("/usr/sbin/lsdev -Cc processor -S 1").read.count("\n")
            elsif File.executable?("/usr/sbin/sysconf") and platform =~ /irix/
              ::IO.popen("/usr/sbin/sysconf NPROC_ONLN").read.to_i
            elsif File.executable?("/usr/sbin/sysctl")
              ::IO.popen("/usr/sbin/sysctl -n hw.ncpu").read.to_i
            elsif File.executable?("/sbin/sysctl")
              ::IO.popen("/sbin/sysctl -n hw.ncpu").read.to_i
            else
              $stderr.puts "Unknown platform: #{platform}"
              $stderr.puts "Assuming 1 processor."
              1
            end
          end
        end

        def max_memory
          @memory_size ||= begin
            if platform =~ /mingw|mswin/
              #require 'win32ole'
              # Completely untested.  Probably won't work
              #result = WIN32OLE.connect("winmgmts://").ExecQuery(
              #          "select Win32_LogicalMemoryConfiguration from Win32_MemoryArray")
              #result.to_i
              $stderr.puts "I don't know how to get memsize in windows.  Assume 1024 MB"
              1024
            elsif File.readable?("/proc/meminfo")
              ::IO.read("/proc/meminfo")[/^MemTotal:\s+(?<size>\d+)\s+/, "size"].to_i / 1024
            else
              $stderr.puts "Unknown platform: #{platform}"
              $stderr.puts "Assuming 1024 MB RAM"
              1024
            end
          end
        end
      end
    end
  end
end
