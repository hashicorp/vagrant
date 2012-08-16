require 'net/http'
require 'net/https'
require 'uri'
require 'base64'

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
        proxy_uri = resolve_proxy(uri)

        http = Net::HTTP.new(uri.host, uri.port, proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password)
        http.read_timeout = nil # Disable the read timeout, just let it try to download

        if uri.scheme == "https"
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        http.start do |h|
          @ui.info I18n.t("vagrant.downloaders.http.download", :url => source_url)

          headers = nil
          if uri.user && uri.password
            headers = {'Authorization' => 'Basic ' + Base64.encode64(uri.user + ':' + uri.password)}
          end

          h.request_get(uri.request_uri, headers) do |response|
            if response.is_a?(Net::HTTPRedirection)
              # Follow the HTTP redirect.
              # TODO: Error on some redirect limit
              download!(response["Location"], destination_file)
              return
            elsif !response.is_a?(Net::HTTPOK)
              raise Errors::DownloaderHTTPStatusError, :status => response.code
            end

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
                @ui.clear_line
                @ui.report_progress(progress, total)
                segment_count = 0
              end

              # Store the segment
              destination_file.write(segment)
            end

            # Clear the line one last time so that the progress meter disappears
            @ui.clear_line
          end
        end
      rescue SocketError
        raise Errors::DownloaderHTTPSocketError
      end

      private

      # This method respects the "http_proxy" and "no_proxy" environmental
      # variables so that HTTP proxies can properly be used with Vagrant.
      def resolve_proxy(source_uri)
        proxy_string = ENV["http_proxy"] || ""
        if !proxy_string.empty? && ENV.has_key?("no_proxy")
          # Respect the "no_proxy" environmental variable which contains a list
          # of hosts that a proxy should not be used for.
          ENV["no_proxy"].split(",").each do |host|
            if source_uri.host =~ /#{Regexp.quote(host.strip)}$/
              proxy_string = ""
              break
            end
          end
        end

        URI.parse(proxy_string)
      end
    end
  end
end
