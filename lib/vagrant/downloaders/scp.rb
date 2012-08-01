require 'net/scp'
require 'uri'

module Vagrant
  module Downloaders
    # Downloads a file from an SCP(SSH) URL to a temporary file. This
    # downloader reports its progress to stdout while downloading.
    class SCP < Base
      def self.match?(uri)
        # URI.parse barfs on '<drive letter>:\\files \on\ windows'
        extracted = URI.extract(uri, "scp").first
        extracted && extracted.include?(uri)
      end

      def download!(source_url, destination_file)
        uri = URI.parse(source_url)

        # strip the first slash to make URIs point into the users home directory by default
        # to reference files relative to the root of the server, use 2 slashes in the URI
        remote_file = uri.path.sub(/^\//,"")

        ssh = Net::SSH.start(uri.host, uri.user)

        scp = ssh.scp

        @ui.info I18n.t("vagrant.downloaders.http.download", :url => source_url)

        scp.download!(remote_file, destination_file) do |ch, name, received, total|

          @ui.clear_line
          @ui.report_progress(received, total)

        end

        # Clear the line one last time so that the progress meter disappears
        @ui.clear_line
      end
    end
  end
end
