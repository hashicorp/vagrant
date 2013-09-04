require "log4r"

require "vagrant/util/busy"
require "vagrant/util/subprocess"

module Vagrant
  module Util
    # This class downloads files using various protocols by subprocessing
    # to cURL. cURL is a much more capable and complete download tool than
    # a hand-rolled Ruby library, so we defer to its expertise.
    class Downloader
      # Custom user agent provided to cURL so that requests to URL shorteners
      # are properly tracked.
      USER_AGENT = "Vagrant/#{VERSION}"

      def initialize(source, destination, options=nil)
        @logger      = Log4r::Logger.new("vagrant::util::downloader")
        @source      = source.to_s
        @destination = destination.to_s

        # Get the various optional values
        options     ||= {}
        @insecure    = options[:insecure]
        @ui          = options[:ui]
      end

      # This executes the actual download, downloading the source file
      # to the destination with the given options used to initialize this
      # class.
      #
      # If this method returns without an exception, the download
      # succeeded. An exception will be raised if the download failed.
      def download!
        # Build the list of parameters to execute with cURL
        options = [
          "--fail",
          "--location",
          "--max-redirs", "10",
          "--user-agent", USER_AGENT,
          "--output", @destination
        ]

        options << "--insecure" if @insecure
        options << @source

        # Specify some options for the subprocess
        subprocess_options = {}

        # If we're in Vagrant, then we use the packaged CA bundle
        if Vagrant.in_installer?
          subprocess_options[:env] ||= {}
          subprocess_options[:env]["CURL_CA_BUNDLE"] =
            File.expand_path("cacert.pem", ENV["VAGRANT_INSTALLER_EMBEDDED_DIR"])
        end

        # This variable can contain the proc that'll be sent to
        # the subprocess execute.
        data_proc = nil

        if @ui
          # If we're outputting progress, then setup the subprocess to
          # tell us output so we can parse it out.
          subprocess_options[:notify] = :stderr

          progress_data = ""
          progress_regexp = /(\r(.+?))\r/

          # Setup the proc that'll receive the real-time data from
          # the downloader.
          data_proc = Proc.new do |type, data|
            # Type will always be "stderr" because that is the only
            # type of data we're subscribed for notifications.

            # Accumulate progress_data
            progress_data << data

            while true
              # If we have a full amount of column data (two "\r") then
              # we report new progress reports. Otherwise, just keep
              # accumulating.
              match = progress_regexp.match(progress_data)
              break if !match
              data = match[2]
              progress_data.gsub!(match[1], "")

              # Ignore the first \r and split by whitespace to grab the columns
              columns = data.strip.split(/\s+/)

              # COLUMN DATA:
              #
              # 0 - % total
              # 1 - Total size
              # 2 - % received
              # 3 - Received size
              # 4 - % transferred
              # 5 - Transferred size
              # 6 - Average download speed
              # 7 - Average upload speed
              # 9 - Total time
              # 9 - Time spent
              # 10 - Time left
              # 11 - Current speed

              output = "Progress: #{columns[0]}% (Rate: #{columns[11]}/s, Estimated time remaining: #{columns[10]})"
              @ui.clear_line
              @ui.info(output, :new_line => false)
            end
          end
        end

        # Add the subprocess options onto the options we'll execute with
        options << subprocess_options

        # Create the callback that is called if we are interrupted
        interrupted  = false
        int_callback = Proc.new do
          @logger.info("Downloader interrupted!")
          interrupted = true
        end

        @logger.info("Downloader starting download: ")
        @logger.info("  -- Source: #{@source}")
        @logger.info("  -- Destination: #{@destination}")

        # Execute!
        result = Busy.busy(int_callback) do
          Subprocess.execute("curl", *options, &data_proc)
        end

        # If the download was interrupted, then raise a specific error
        raise Errors::DownloaderInterrupted if interrupted

        # If we're outputting to the UI, clear the output to
        # avoid lingering progress meters.
        @ui.clear_line if @ui

        # If it didn't exit successfully, we need to parse the data and
        # show an error message.
        if result.exit_code != 0
          @logger.warn("Downloader exit code: #{result.exit_code}")
          parts    = result.stderr.split(/\n*curl:\s+\(\d+\)\s*/, 2)
          parts[1] ||= ""
          raise Errors::DownloaderError, :message => parts[1].chomp
        end

        # Everything succeeded
        true
      end
    end
  end
end
