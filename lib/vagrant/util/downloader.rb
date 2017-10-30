require "uri"

require "log4r"
require "digest/md5"
require "digest/sha1"
require "vagrant/util/busy"
require "vagrant/util/platform"
require "vagrant/util/subprocess"

module Vagrant
  module Util
    # This class downloads files using various protocols by subprocessing
    # to cURL. cURL is a much more capable and complete download tool than
    # a hand-rolled Ruby library, so we defer to its expertise.
    class Downloader
      # Custom user agent provided to cURL so that requests to URL shorteners
      # are properly tracked.
      #
      #     Vagrant/1.7.4 (+https://www.vagrantup.com; ruby2.1.0)
      USER_AGENT = "Vagrant/#{VERSION} (+https://www.vagrantup.com; #{RUBY_ENGINE}#{RUBY_VERSION})".freeze

      # Supported file checksum
      CHECKSUM_MAP = {
        :md5 => Digest::MD5,
        :sha1 => Digest::SHA1
      }.freeze

      attr_reader :source
      attr_reader :destination

      def initialize(source, destination, options=nil)
        options     ||= {}

        @logger      = Log4r::Logger.new("vagrant::util::downloader")
        @source      = source.to_s
        @destination = destination.to_s

        begin
          url = URI.parse(@source)
          if url.scheme && url.scheme.start_with?("http") && url.user
            auth = "#{URI.unescape(url.user)}"
            auth += ":#{URI.unescape(url.password)}" if url.password
            url.user = nil
            url.password = nil
            options[:auth] ||= auth
            @source = url.to_s
          end
        rescue URI::InvalidURIError
          # Ignore, since its clearly not HTTP
        end

        # Get the various optional values
        @auth        = options[:auth]
        @ca_cert     = options[:ca_cert]
        @ca_path     = options[:ca_path]
        @continue    = options[:continue]
        @headers     = options[:headers]
        @insecure    = options[:insecure]
        @ui          = options[:ui]
        @client_cert = options[:client_cert]
        @location_trusted = options[:location_trusted]
        @checksums   = {
          :md5 => options[:md5],
          :sha1 => options[:sha1]
        }
      end

      # This executes the actual download, downloading the source file
      # to the destination with the given options used to initialize this
      # class.
      #
      # If this method returns without an exception, the download
      # succeeded. An exception will be raised if the download failed.
      def download!
        # This variable can contain the proc that'll be sent to
        # the subprocess execute.
        data_proc = nil

        extra_subprocess_opts = {}
        if @ui
          # If we're outputting progress, then setup the subprocess to
          # tell us output so we can parse it out.
          extra_subprocess_opts[:notify] = :stderr

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
              @ui.detail(output, new_line: false)
            end
          end
        end

        @logger.info("Downloader starting download: ")
        @logger.info("  -- Source: #{@source}")
        @logger.info("  -- Destination: #{@destination}")

        retried = false
        begin
          # Get the command line args and the subprocess opts based
          # on our downloader settings.
          options, subprocess_options = self.options
          options += ["--output", @destination]
          options << @source

          # Merge in any extra options we set
          subprocess_options.merge!(extra_subprocess_opts)

          # Go!
          execute_curl(options, subprocess_options, &data_proc)
        rescue Errors::DownloaderError => e
          # If we already retried, raise it.
          raise if retried

          @logger.error("Exit code: #{e.extra_data[:code]}")

          # If its any error other than 33, it is an error.
          raise if e.extra_data[:code].to_i != 33

          # Exit code 33 means that the server doesn't support ranges.
          # In this case, try again without resume.
          @logger.error("Error is server doesn't support byte ranges. Retrying from scratch.")
          @continue = false
          retried = true
          retry
        ensure
          # If we're outputting to the UI, clear the output to
          # avoid lingering progress meters.
          if @ui
            @ui.clear_line

            # Windows doesn't clear properly for some reason, so we just
            # output one more newline.
            @ui.detail("") if Platform.windows?
          end
        end

        validate_download!(@source, @destination, @checksums)

        # Everything succeeded
        true
      end

      # Does a HEAD request of the URL and returns the output.
      def head
        options, subprocess_options = self.options
        options.unshift("-I")
        options << @source

        @logger.info("HEAD: #{@source}")
        result = execute_curl(options, subprocess_options)
        result.stdout
      end

      protected

      # Apply any checksum validations based on provided
      # options content
      #
      # @param source [String] Source of file
      # @param path [String, Pathname] local file path
      # @param checksums [Hash] User provided options
      # @option checksums [String] :md5 Compare MD5 checksum
      # @option checksums [String] :sha1 Compare SHA1 checksum
      # @return [Boolean]
      def validate_download!(source, path, checksums)
        CHECKSUM_MAP.each do |type, klass|
          if checksums[type]
            result = checksum_file(klass, path)
            @logger.debug("Validating checksum (#{type}) for #{source}. " \
              "expected: #{checksums[type]} actual: #{result}")
            if checksums[type] != result
              raise Errors::DownloaderChecksumError.new(
                source: source,
                path: path,
                type: type,
                expected_checksum: checksums[type],
                actual_checksum: result
              )
            end
          end
        end
        true
      end

      # Generate checksum on given file
      #
      # @param digest_class [Class] Digest class to use for generating checksum
      # @param path [String, Pathname] Path to file
      # @return [String] hexdigest result
      def checksum_file(digest_class, path)
        digester = digest_class.new
        digester.file(path)
        digester.hexdigest
      end

      def execute_curl(options, subprocess_options, &data_proc)
        options = options.dup
        options << subprocess_options

        # Create the callback that is called if we are interrupted
        interrupted  = false
        int_callback = Proc.new do
          @logger.info("Downloader interrupted!")
          interrupted = true
        end

        # Execute!
        result = Busy.busy(int_callback) do
          Subprocess.execute("curl", *options, &data_proc)
        end

        # If the download was interrupted, then raise a specific error
        raise Errors::DownloaderInterrupted if interrupted

        # If it didn't exit successfully, we need to parse the data and
        # show an error message.
        if result.exit_code != 0
          @logger.warn("Downloader exit code: #{result.exit_code}")
          parts    = result.stderr.split(/\n*curl:\s+\(\d+\)\s*/, 2)
          parts[1] ||= ""
          raise Errors::DownloaderError,
            code: result.exit_code,
            message: parts[1].chomp
        end

        result
      end

      # Returns the varoius cURL and subprocess options.
      #
      # @return [Array<Array, Hash>]
      def options
        # Build the list of parameters to execute with cURL
        options = [
          "-q",
          "--fail",
          "--location",
          "--max-redirs", "10",
          "--user-agent", USER_AGENT,
        ]

        options += ["--cacert", @ca_cert] if @ca_cert
        options += ["--capath", @ca_path] if @ca_path
        options += ["--continue-at", "-"] if @continue
        options << "--insecure" if @insecure
        options << "--cert" << @client_cert if @client_cert
        options << "-u" << @auth if @auth
        options << "--location-trusted" if @location_trusted

        if @headers
          Array(@headers).each do |header|
            options << "-H" << header
          end
        end

        # Specify some options for the subprocess
        subprocess_options = {}

        # If we're in Vagrant, then we use the packaged CA bundle
        if Vagrant.in_installer?
          subprocess_options[:env] ||= {}
          subprocess_options[:env]["CURL_CA_BUNDLE"] = ENV["CURL_CA_BUNDLE"]
        end

        return [options, subprocess_options]
      end
    end
  end
end
