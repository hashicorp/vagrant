require "digest/sha1"
require "log4r"

require "vagrant/util/downloader"
require "vagrant/util/file_checksum"
require "vagrant/util/platform"

module Vagrant
  module Action
    module Builtin
      # This middleware will download a remote box and add it to the
      # given box collection.
      class BoxAdd
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::box_add")
        end

        def call(env)
          @download_interrupted = false

          box_name = env[:box_name]

          box_formats = env[:box_provider]
          if box_formats
            # Determine the formats a box can support and allow the box to
            # be any of those formats.
            provider_plugin = Vagrant.plugin("2").manager.providers[env[:box_provider]]
            if provider_plugin
              box_formats = provider_plugin[1][:box_format]
              box_formats ||= env[:box_provider]
            end
          end

          # Determine the checksum type to use
          checksum = (env[:box_checksum] || "").to_s
          checksum_klass = nil
          if env[:box_checksum_type]
            checksum_klass = case env[:box_checksum_type].to_sym
            when :md5
              Digest::MD5
            when :sha1
              Digest::SHA1
            when :sha256
              Digest::SHA2
            else
              raise Errors::BoxChecksumInvalidType,
                type: env[:box_checksum_type].to_s
            end
          end

          # Go through each URL and attempt to download it
          download_error = nil
          download_url = nil
          urls = env[:box_url]
          urls = [env[:box_url]] if !urls.is_a?(Array)
          urls.each do |url|
            begin
              @temp_path = download_box_url(url, env)
              download_error = nil
              download_url = url
            rescue Errors::DownloaderError => e
              env[:ui].error(I18n.t(
                "vagrant.actions.box.download.download_failed"))
              download_error = e
            end

            # If we were interrupted during this download, then just return
            # at this point, we don't need to try anymore.
            if @download_interrupted
              @logger.warn("Download interrupted, not trying any more box URLs.")
              return
            end
          end

          # If all the URLs failed, then raise an exception
          raise download_error if download_error

          if checksum_klass
            @logger.info("Validating checksum with #{checksum_klass}")
            @logger.info("Expected checksum: #{checksum}")

            env[:ui].info(I18n.t("vagrant.actions.box.add.checksumming",
              name: box_name))
            actual = FileChecksum.new(@temp_path, checksum_klass).checksum
            if actual != checksum
              raise Errors::BoxChecksumMismatch,
                actual: actual,
                expected: checksum
            end
          end

          # Add the box
          env[:ui].info I18n.t("vagrant.actions.box.add.adding", :name => box_name)
          box_added = nil
          begin
            box_added = env[:box_collection].add(
              @temp_path, box_name, box_formats, env[:box_force])
          rescue Vagrant::Errors::BoxUpgradeRequired
            # Upgrade the box
            env[:box_collection].upgrade(box_name)

            # Try adding it again
            retry
          end

          # Call the 'recover' method in all cases to clean up the
          # downloaded temporary file.
          recover(env)

          # Success, we added a box!
          env[:ui].success(
            I18n.t("vagrant.actions.box.add.added", name: box_added.name, provider: box_added.provider))

          # Persists URL used on download and the time it was added
          write_extra_info(box_added, download_url)

          # Passes on the newly added box to the rest of the middleware chain
          env[:box_added] = box_added

          # Carry on!
          @app.call(env)
        end

        def recover(env)
          if @temp_path && File.exist?(@temp_path) && !@download_interrupted
            File.unlink(@temp_path)
          end
        end

        def download_box_url(url, env)
          temp_path = env[:tmp_path].join("box" + Digest::SHA1.hexdigest(url))
          @logger.info("Downloading box: #{url} => #{temp_path}")

          if File.file?(url) || url !~ /^[a-z0-9]+:.*$/i
            @logger.info("URL is a file or protocol not found and assuming file.")
            file_path = File.expand_path(url)
            file_path = Util::Platform.cygwin_windows_path(file_path)
            url = "file:#{file_path}"
          end

          downloader_options = {}
          downloader_options[:ca_cert] = env[:box_download_ca_cert]
          downloader_options[:continue] = true
          downloader_options[:insecure] = env[:box_download_insecure]
          downloader_options[:ui] = env[:ui]
          downloader_options[:client_cert] = env[:box_client_cert]

          # If the temporary path exists, verify it is not too old. If its
          # too old, delete it first because the data may have changed.
          if temp_path.file?
            delete = false
            if env[:box_clean]
              @logger.info("Cleaning existing temp box file.")
              delete = true
            elsif temp_path.mtime.to_i < (Time.now.to_i - 6 * 60 * 60)
              @logger.info("Existing temp file is too old. Removing.")
              delete = true
            end

            temp_path.unlink if delete
          end

          # Download the box to a temporary path. We store the temporary
          # path as an instance variable so that the `#recover` method can
          # access it.
          env[:ui].info(I18n.t(
            "vagrant.actions.box.download.downloading",
            url: url))
          if temp_path.file?
            env[:ui].info(I18n.t("vagrant.actions.box.download.resuming"))
          end

          begin
            downloader = Util::Downloader.new(url, temp_path, downloader_options)
            downloader.download!
          rescue Errors::DownloaderInterrupted
            # The downloader was interrupted, so just return, because that
            # means we were interrupted as well.
            @download_interrupted = true
            env[:ui].info(I18n.t("vagrant.actions.box.download.interrupted"))
          rescue Errors::DownloaderError
            # The download failed for some reason, clean out the temp path
            temp_path.unlink if temp_path.file?
            raise
          end

          temp_path
        end

        def write_extra_info(box_added, url)
          info = {'url' => url, 'downloaded_at' => Time.now.utc}
          box_added.directory.join('info.json').open("w+") do |f|
            f.write(JSON.dump(info))
          end
        end
      end
    end
  end
end
