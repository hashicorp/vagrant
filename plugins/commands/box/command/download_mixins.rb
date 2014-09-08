module VagrantPlugins
  module CommandBox
    module DownloadMixins
      # This adds common download command line flags to the given
      # OptionParser, storing the result in the `options` dictionary.
      #
      # @param [OptionParser] parser
      # @param [Hash] options
      def build_download_options(parser, options)
        # Add the options
        parser.on("--insecure", "Do not validate SSL certificates") do |i|
          options[:insecure] = i
        end

        parser.on("--cacert FILE", String, "CA certificate for SSL download") do |c|
          options[:ca_cert] = c
        end

        parser.on("--capath DIR", String, "CA certificate directory for SSL download") do |c|
          options[:ca_path] = c
        end

        parser.on("--cert FILE", String, "A client SSL cert, if needed") do |c|
          options[:client_cert] = c
        end
      end
    end
  end
end
