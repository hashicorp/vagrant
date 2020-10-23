require "uri"

require "log4r"
require "vagrant/util/busy"
require "vagrant/util/platform"
require "vagrant/util/subprocess"
require "vagrant/util/curl_helper"

module Vagrant
  module Util
    # This class uploads files using various protocols by subprocessing
    # to cURL. cURL is a much more capable and complete download tool than
    # a hand-rolled Ruby library, so we defer to its expertise.
    class Uploader

      # @param [String] destination Valid URL to upload file to
      # @param [String] file Location of file to upload on disk
      # @param [Hash] options
      # @option options [Vagrant::UI] :ui UI interface for output
      # @option options [String, Symbol] :method Request method for upload
      def initialize(destination, file, options=nil)
        options ||= {}
        @logger         = Log4r::Logger.new("vagrant::util::uploader")
        @destination    = destination.to_s
        @file           = file.to_s
        @ui             = options[:ui]
        @request_method = options[:method]

        if !@request_method
          @request_method = "PUT"
        end
        @request_method = @request_method.to_s.upcase
      end

      def upload!
        data_proc = Vagrant::Util::CurlHelper.capture_output_proc(@logger, @ui)

        @logger.info("Uploader starting upload: ")
        @logger.info("  -- Source: #{@file}")
        @logger.info("  -- Destination: #{@destination}")

        options = build_options
        subprocess_options = {notify: :stderr}

        begin
          execute_curl(options, subprocess_options, &data_proc)
        rescue Errors::UploaderError => e
          raise
        ensure
          @ui.clear_line if @ui
        end
      end

      protected

      def build_options
        options = [@destination, "--request", @request_method, "--upload-file", @file, "--fail"]
        return options
      end

      def execute_curl(options, subprocess_options, &data_proc)
        options = options.dup
        options << subprocess_options

        # Create the callback that is called if we are interrupted
        interrupted  = false
        int_callback = Proc.new do
          @logger.info("Uploader interrupted!")
          interrupted = true
        end

        # Execute!
        result = Busy.busy(int_callback) do
          Subprocess.execute("curl", *options, &data_proc)
        end

        # If the upload was interrupted, then raise a specific error
        raise Errors::UploaderInterrupted if interrupted

        # If it didn't exit successfully, we need to parse the data and
        # show an error message.
        if result.exit_code != 0
          @logger.warn("Uploader exit code: #{result.exit_code}")
          check = result.stderr.match(/\n*curl:\s+\((?<code>\d+)\)\s*(?<error>.*)$/)
          if !check
            err_msg = result.stderr
          else
            err_msg = check[:error]
          end

          raise Errors::UploaderError,
            exit_code: result.exit_code,
            message: err_msg
        end

        if @ui
          @ui.clear_line
          # Windows doesn't clear properly for some reason, so we just
          # output one more newline.
          @ui.detail("") if Platform.windows?
        end
        result
      end
    end
  end
end
