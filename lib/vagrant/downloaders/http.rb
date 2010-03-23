module Vagrant
  module Downloaders
    # Downloads a file from an HTTP URL to a temporary file. This
    # downloader reports its progress to stdout while downloading.
    class HTTP < Base
      # ANSI escape code to clear lines from cursor to end of line
      CL_RESET = "\r\e[0K"

      def self.match?(uri)
        # URI.parse barfs on '<drive letter>:\\files \on\ windows'
        # TODO temprorary
        extracted = URI.extract(uri).first
        extracted && extracted.include?(uri)
      end
        
      def download!(source_url, destination_file)
        Net::HTTP.get_response(URI.parse(source_url)) do |response|
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
              report_progress(progress, total)
              segment_count = 0
            end

            # Store the segment
            destination_file.write(segment)
          end
        end

        complete_progress
      end

      def report_progress(progress, total)
        percent = (progress.to_f / total.to_f) * 100
        print "#{CL_RESET}Download Progress: #{percent.to_i}% (#{progress} / #{total})"
        $stdout.flush
      end

      def complete_progress
        # Just clear the line back out
        print "#{CL_RESET}"
      end
    end
  end
end
