require "log4r"

require "vagrant/util/subprocess"

module Vagrant
  module Util
    # This class downloads files using various protocols by subprocessing
    # to cURL. cURL is a much more capable and complete download tool than
    # a hand-rolled Ruby library, so we defer to it's expertise.
    class Downloader
      def initialize(source, destination, options=nil)
        @logger      = Log4r::Logger.new("vagrant::util::downloader")
        @source      = source
        @destination = destination

        # Get the various optional values
        @options     ||= {}
        @ui          = @options[:ui]
      end

      # This executes the actual download, downloading the source file
      # to the destination with the given opens used to initialize this
      # class.
      #
      # If this method returns without an exception, the download
      # succeeded. An exception will be raised if the download failed.
      def download!
        # Build the list of parameters to execute with cURL
        options = [
          "--fail",
          "--output", @destination,
          @source
        ]

        # This variable can contain the proc that'll be sent to
        # the subprocess execute.
        data_proc = nil

        if @ui
          # If we're outputting progress, then setup the subprocess to
          # tell us output so we can parse it out.
          options << { :notify => :stderr }

          # Setup the proc that'll receive the real-time data from
          # the downloader.
          data_proc = Proc.new do |type, data|
            # Type will always be "stderr" because that is the only
            # type of data we're subscribed for notifications.

            # If the data doesn't start with a \r then it isn't a progress
            # notification, so ignore it.
            next if data[0] != "\r"

            # Ignore the first \r and split by whitespace to grab the columns
            columns = data[1..-1].split(/\s+/)

            # COLUMN DATA:
            #
            # 0 - blank
            # 1 - % total
            # 2 - Total size
            # 3 - % received
            # 4 - Received size
            # 5 - % transferred
            # 6 - Transferred size
            # 7 - Average download speed
            # 8 - Average upload speed
            # 9 - Total time
            # 10 - Time spent
            # 11 - Time left
            # 12 - Current speed

            output = "Progress: #{columns[1]}% (Rate: #{columns[12]}/s, Estimated time remaining: #{columns[11]}"
            @ui.clear_line
            @ui.info(output, :new_line => false)
          end
        end

        @logger.info("Downloader starting download: ")
        @logger.info("  -- Source: #{@source}")
        @logger.info("  -- Destination: #{@destination}")

        # Execute!
        result = Subprocess.execute("curl", *options, &data_proc)

        # If it didn't exit successfully, we need to parse the data and
        # show an error message.
        if result.exit_code != 0
          parts = result.stderr.split(/\ncurl:\s+\(\d+\)\s*/, 2)
          raise Errors::DownloaderError, :message => parts[1]
        end

        # Everything succeeded
        true
      end
    end
  end
end
