require 'stringio'

module Vagrant
  module Util
    class LineBuffer
      def initialize
        @buffer = StringIO.new
      end

      def lines(data, &block)
        if data == nil
          return
        end
        remaining_buffer = StringIO.new
        @buffer << data
        @buffer.string.each_line do |line|
          if line.end_with? "\n"
            block.call(line.rstrip)
          else
            remaining_buffer << line
            break
          end
        end
        @buffer = remaining_buffer
      end

      def remaining(&block)
        if @buffer.length > 0
          block.call(@buffer.string.rstrip)
          @buffer = StringIO.new
        end
      end
    end
  end
end
