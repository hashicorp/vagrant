module Vagrant
  module Util
    class FileMutex
      def initialize(mutex_path)
        @mutex_path = mutex_path
      end

      def with_lock(&block)
        lock
        block.call
      ensure
        unlock
      end

      def lock
        if File.file?(@mutex_path)
          raise Errors::VagrantLocked,
            lock_file_path: @mutex_path
        end
        
        File.write(@mutex_path, "")
      end

      def unlock
        File.delete(@mutex_path) if File.file?(@mutex_path)
      end
    end
  end
end
