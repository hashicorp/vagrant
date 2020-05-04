require "vagrant/util/platform"

module Vagrant
  module Util
    class IO
      # The chunk size for reading from subprocess IO.
      READ_CHUNK_SIZE = 4096

      # Reads data from an IO object while it can, returning the data it reads.
      # When it encounters a case when it can't read anymore, it returns the
      # data.
      #
      # @return [String]
      def self.read_until_block(io)
        data = ""

        while true
          begin
            if Platform.windows?
              # Windows doesn't support non-blocking reads on
              # file descriptors or pipes so we have to get
              # a bit more creative.

              # Check if data is actually ready on this IO device.
              # We have to do this since `readpartial` will actually block
              # until data is available, which can cause blocking forever
              # in some cases.
              results = ::IO.select([io], nil, nil, 1.0)
              break if !results || results[0].empty?

              # Read!
              data << io.readpartial(READ_CHUNK_SIZE).encode(
                "UTF-8", Encoding.default_external,
                invalid: :replace,
                undef: :replace
              )
            else
              # Do a simple non-blocking read on the IO object
              data << io.read_nonblock(READ_CHUNK_SIZE)
            end
          rescue EOFError, Errno::EAGAIN, ::IO::WaitReadable
            break
          end
        end

        data
      end
    end
  end
end
