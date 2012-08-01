module Vagrant
  module Util
    class FileUtil
      # Cross-platform way of finding an executable in the $PATH.
      #
      #   which('ruby') #=> /usr/bin/ruby
      #   by http://stackoverflow.com/users/11687/mislav
      #
      # This code is adapted from the following post by mislav:
      #   http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
      def self.which(cmd)

        # If the PATHEXT variable is empty, we're on *nix and need to find the exact filename
        exts = nil
        if !Util::Platform.windows? || ENV['PATHEXT'].nil?
          exts = ['']
        # On Windows: if filename contains an extension, we must match that exact filename
        elsif File.extname(cmd).length != 0
          exts = ['']
        # On Windows: otherwise try to match all possible executable file extensions (.EXE .COM .BAT etc.)
        else
          exts = ENV['PATHEXT'].split(';')
        end

        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each do |ext|
            exe = "#{path}#{File::SEPARATOR}#{cmd}#{ext}"
            return exe if File.executable? exe
          end
        end
        
        return nil
      end
    end
  end
end
