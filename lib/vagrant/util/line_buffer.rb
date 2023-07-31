# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module Util
    class LineBuffer

      # Maximum number of characters to buffer before sending
      # to callback without detecting a new line
      MAX_LINE_LENGTH = 5000.freeze

      # Create a new line buffer. The registered block
      # will be called when a new line is encountered on
      # provided input, or the max line length is reached
      def initialize(&callback)
        raise ArgumentError,
          "Expected callback but received none" if callback.nil?
        @mu = Mutex.new
        @callback = callback
        @buffer = ""
      end

      # Add string data to output
      #
      # @param [String] str String of data to output
      # @return [self]
      def <<(str)
        @mu.synchronize do
          while i = str.index("\n")
            @callback.call((@buffer + str[0, i+1]).rstrip)
            @buffer.clear
            str = str[i+1, str.length].to_s
          end

          @buffer << str.to_s

          if @buffer.length > MAX_LINE_LENGTH
            @callback.call(@buffer.dup)
            @buffer.clear
          end
        end
        self
      end

      # Closes the buffer. Any remaining data that has
      # been buffered will be given to the callback.
      # Once closed the instance will no longer be usable.
      #
      # @return [self]
      def close
        @mu.synchronize do
          # Send any remaining output on the buffer
          @callback.call(@buffer.dup) if !@buffer.empty?
          # Disable this buffer instance
          @callback = nil
          @buffer.clear
          @buffer.freeze
        end
        self
      end
    end
  end
end
