# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module Vagrant
  module Util
    # Utility to provide a simple mutex via file lock
    class FileMutex
      # Create a new FileMutex instance
      #
      # @param mutex_path [String] path for file
      def initialize(mutex_path)
        @mutex_path = mutex_path
      end

      # Execute provided block within lock and unlock
      # when completed
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

      # Attempt to acquire the lock
      def lock
        if lock_file.flock(File::LOCK_EX|File::LOCK_NB) === false
          raise Errors::VagrantLocked, lock_file_path: @mutex_path
        end
      end

      # Unlock the file
      def unlock
        lock_file.flock(File::LOCK_UN)
        lock_file.close
        File.delete(@mutex_path) if File.file?(@mutex_path)
      end

      protected

      def lock_file
        return @lock_file if @lock_file && !@lock_file.closed?
        @lock_file = File.open(@mutex_path, "w+")
      end
    end
  end
end
