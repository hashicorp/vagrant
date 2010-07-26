require 'net/http'
require 'net/https'
require 'open-uri'
require 'uri'

module Vagrant
  module Downloaders
    # Downloads a file from an HTTP URL to a temporary file. This
    # downloader reports its progress to stdout while downloading.
    class HTTP < Base
      def self.match?(uri)
        # URI.parse barfs on '<drive letter>:\\files \on\ windows'
        extracted = URI.extract(uri).first
        extracted && extracted.include?(uri)
      end

      def download!(source_url, destination_file)
        uri = URI.parse(source_url)
        http = Net::HTTP.new(uri.host, uri.port)
        if uri.scheme == "https"
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        http.start do |h|
          h.request_get(uri.request_uri) do |response|
            total = response.content_length
            progress = 0
            segment_count = 0

            response.read_body do |segment|
              # Report the progress out
              progress += segment.length
              segment_count += 1

              # Progress reporting is limited to every 25 segments just so
              # we're not constantly updating
              if segment_count % 25 == 0
                env.logger.report_progress(progress, total)
                segment_count = 0
              end

              # Store the segment
              destination_file.write(segment)
            end
          end
        end

        env.logger.clear_progress
      rescue SocketError
        env.error!(:box_download_http_socket_error, :box_url => source_url)
      end
    end
  end
end
