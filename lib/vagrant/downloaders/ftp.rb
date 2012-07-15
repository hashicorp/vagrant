require 'net/ftp'
require 'uri'

module Vagrant
  module Downloaders
    # Downloads a file from an FTP URL to a temporary file. This
    # downloader reports its progress to stdout while downloading.
    class FTP < Base
      def self.match?(uri)
        # Copied from HTTP downloader
        # Not sure if it's good to repeat myself like this
        extracted = URI.extract(uri).first
        extracted && extracted.include?(uri) &&
          URI.parse(extracted).scheme.downcase == 'ftp'
      end

      def download!(source_url, destination_file)
        # Let Net::FTP handle file manipulation
        destination_file.close unless destination_file.closed?

        uri = URI.parse(source_url).normalize
        path = uri.path
        dir = ::File.dirname path
        filename = ::File.basename path

        raise BadFilename if filename.empty?

        ftp = Net::FTP.new uri.host, uri.user || 'anonymous', uri.password
        ftp.chdir(dir.empty? ? '/' : dir)

        @ui.info I18n.t("vagrant.downloaders.ftp.download", :url => uri.to_s)

        total = ftp.size filename
        progress = 0
        segment_count = 0

        ftp.getbinaryfile filename, destination_file.path do |segment|
          progress += segment.length
          segment_count += 1

          if segment_count % 25 == 0
            @ui.clear_line
            @ui.report_progress(progress, total)
            segment_count = 0
          end
        end

        @ui.clear_line
      rescue Errno::ECONNREFUSED
        raise Errors::DownloaderFTPConnError
      rescue Net::FTPTempError => ex
        raise Errors::DownloaderFTPServerFault, ex.message
      rescue Net::FTPPermError => ex
        case ex.message[0, 3]
        when '550'
          raise Errors::DownloaderFTPBadPathError
        when '530'
          raise Errors::DownloaderFTPAuthError
        else
          raise Errors::DownloaderFTPError, ex.message
        end
      end
    end
  end
end
