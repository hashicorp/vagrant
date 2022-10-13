module Vagrant
  module Util
    class CurlHelper

      # Hosts that do not require notification on redirect
      SILENCED_HOSTS = [
        "vagrantcloud.com".freeze,
        "vagrantup.com".freeze
      ].freeze

      def self.capture_output_proc(logger, ui, source=nil)
        progress_data = ""
        progress_regexp = /^\r\s*(\d.+?)\r/m

        # Setup the proc that'll receive the real-time data from
        # the downloader.
        data_proc = Proc.new do |type, data|
          # Type will always be "stderr" because that is the only
          # type of data we're subscribed for notifications.

          # Accumulate progress_data
          progress_data << data

          while true
            # If the download has been redirected and we are no longer downloading
            # from the original host, notify the user that the target host has
            # changed from the source.
            if progress_data.include?("Location")
              location = progress_data.scan(/(^|[^\w-])Location: (.+?)$/m).flatten.compact.last.to_s.strip
              if !location.empty?
                location_uri = URI.parse(location)

                unless location_uri.host.nil?
                  redirect_notify = false
                  logger.info("download redirected to #{location}")
                  source_uri = URI.parse(source)
                  source_host = source_uri.host.to_s.split(".", 2).last
                  location_host = location_uri.host.to_s.split(".", 2).last
                  if !redirect_notify && location_host != source_host && !SILENCED_HOSTS.include?(location_host)
                    ui.rewriting do |ui|
                      ui.clear_line
                      ui.detail "Download redirected to host: #{location_uri.host}"
                    end
                  end
                  redirect_notify = true
                end
              end
              progress_data.replace("")
              break
            end
            # If we have a full amount of column data (two "\r") then
            # we report new progress reports. Otherwise, just keep
            # accumulating.
            match = nil
            check_match = true

            while check_match
              check_match = progress_regexp.match(progress_data)
              if check_match
                data = check_match[1].to_s
                stop = progress_data.index(data) + data.length
                progress_data.slice!(0, stop)

                match = check_match
              end
            end

            break if !match

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
            ui.rewriting do |ui|
              ui.clear_line
              ui.detail(output, new_line: false)
            end
          end
        end

        return data_proc
      end
    end
  end
end
