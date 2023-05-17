module Vagrant
  module Util
    class FileMutex
      def initialize(mutex_path)
        @mutex_path = mutex_path
      end

      def with_lock(&block)
        lock
        begin
          block.call
        rescue => e
          raise e
        ensure
          unlock
        end
      end

      def lock
        File.open(@mutex_path, "w+")  do |f|
          if f.flock(File::LOCK_EX|File::LOCK_NB) === false
            raise Errors::VagrantLocked, lock_file_path: @mutex_path
          end
        end
      end

      def unlock
        File.delete(@mutex_path) if File.file?(@mutex_path)
      end
    end
  end
end
