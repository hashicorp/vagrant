require "cgi"
require "uri"

require "log4r"
require "digest"
require "digest/md5"
require "digest/sha1"
require "vagrant/util/busy"
require "vagrant/util/platform"
require "vagrant/util/subprocess"
require "vagrant/util/curl_helper"
require "vagrant/util/file_checksum"

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
      USER_AGENT = "Vagrant/#{VERSION} (+https://www.vagrantup.com; #{RUBY_ENGINE}#{RUBY_VERSION}) #{ENV['VAGRANT_USER_AGENT_PROVISIONAL_STRING']}".freeze

      # Hosts that do not require notification on redirect
      SILENCED_HOSTS = [
        "vagrantcloud.com".freeze,
        "vagrantup.com".freeze
      ].freeze

      attr_accessor :source
      attr_reader :destination
      attr_accessor :headers

      def initialize(source, destination, options=nil)
        options     ||= {}

        @logger      = Log4r::Logger.new("vagrant::util::downloader")
        @source      = source.to_s
        @destination = destination.to_s

        begin
          url = URI.parse(@source)
          if url.scheme && url.scheme.start_with?("http") && url.user
            auth = "#{CGI.unescape(url.user)}"
            auth += ":#{CGI.unescape(url.password)}" if url.password
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
        @headers     = Array(options[:headers])
        @insecure    = options[:insecure]
        @ui          = options[:ui]
        @client_cert = options[:client_cert]
        @location_trusted = options[:location_trusted]
        @checksums   = {
          :md5 => options[:md5],
          :sha1 => options[:sha1],
          :sha256 => options[:sha256],
          :sha384 => options[:sha384],
          :sha512 => options[:sha512]
        }.compact
        @extra_download_options = options[:box_extra_download_options] || []
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

          data_proc = Vagrant::Util::CurlHelper.capture_output_proc(@logger, @ui, @source)
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
        checksums.each do |type, expected|
          actual = FileChecksum.new(path, type).checksum
          @logger.debug("Validating checksum (#{type}) for #{source}. " \
            "expected: #{expected} actual: #{actual}")
          if actual.casecmp(expected) != 0
            raise Errors::DownloaderChecksumError.new(
              source: source,
              path: path,
              type: type,
              expected_checksum: expected,
              actual_checksum: actual
            )
          end
        end
        true
      end

      def execute_curl(options, subprocess_options, &data_proc)
        options = options.dup
        options.unshift("-q")
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
          check = result.stderr.match(/\n*curl:\s+\((?<code>\d+)\)\s*(?<error>.*)$/)
          if check && check[:code] == "416"
            # All good actually. 416 means there is no more bytes to download
            @logger.warn("Downloader got a 416, but is likely fine. Continuing on...")
          else
            if !check
              err_msg = result.stderr
            else
              err_msg = check[:error]
            end

            raise Errors::DownloaderError,
              code: result.exit_code,
              message: err_msg
          end
        end

        result
      end

      # Returns the various cURL and subprocess options.
      #
      # @return [Array<Array, Hash>]
      def options
        # Build the list of parameters to execute with cURL
        options = [
          "--fail",
          "--location",
          "--max-redirs", "10", "--verbose",
          "--user-agent", USER_AGENT,
        ]

        options += ["--cacert", @ca_cert] if @ca_cert
        options += ["--capath", @ca_path] if @ca_path
        options += ["--continue-at", "-"] if @continue
        options << "--insecure" if @insecure
        options << "--cert" << @client_cert if @client_cert
        options << "-u" << @auth if @auth
        options << "--location-trusted" if @location_trusted

        options.concat(@extra_download_options)

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
