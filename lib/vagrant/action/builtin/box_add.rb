require "digest/sha1"
require "log4r"
require "pathname"
require "uri"

require "vagrant/box_metadata"
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

          url = env[:box_url]
          if metadata_url?(url, env)
            add_from_metadata(env)
          else
            add_direct(env)
          end

          @app.call(env)
        end

        # Adds a box file directly (no metadata component, versioning,
        # etc.)
        def add_direct(env)
          # TODO: what if we have no name
          name = env[:box_name]
          url  = env[:box_url]
          provider = env[:box_provider]
          provider = Array(provider) if provider

          box_add(
            url,
            name,
            "0",
            provider,
            env)
        end

        # Adds a box given that the URL is a metadata document.
        def add_from_metadata(env)
          provider = env[:box_provider]
          provider = Array(provider) if provider
          url = env[:box_url]
          version = env[:box_version]

          metadata = nil
          begin
            metadata_path = download(url, env)

            File.open(metadata_path) do |f|
              metadata = BoxMetadata.new(f)
            end
          ensure
            metadata_path.delete if metadata_path.file?
          end

          metadata_version  = metadata.version(
            version || ">= 0", provider: provider)
          if !metadata_version
            if !provider
              raise Errors::BoxAddNoMatchingVersion,
                constraints: version || ">= 0",
                url: url,
                versions: metadata.versions.join(", ")
            else
              # TODO: show supported providers
              raise Errors::BoxAddNoMatchingProvider,
                requested: provider,
                url: url
            end
          end

          metadata_provider = nil
          if provider
            # If a provider was specified, make sure we get that specific
            # version.
            provider.each do |p|
              metadata_provider = metadata_version.provider(p)
              break if metadata_provider
            end
          elsif metadata_version.providers.length == 1
            # If we have only one provider in the metadata, just use that
            # provider.
            metadata_provider = metadata_version.provider(
              metadata_version.providers.first)
          end

          box_add(
            metadata_provider.url,
            metadata.name,
            metadata_version.version,
            metadata_provider.name, env)
        end

=begin
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
        end
=end

        protected

        # Shared helper to add a box once you know various details
        # about it. Shared between adding via metadata or by direct.
        #
        # @param [String] url
        # @param [String] name
        # @param [String] version
        # @param [String] provider
        # @param [Hash] env
        # @return [Box]
        def box_add(url, name, version, provider, env, **opts)
          env[:ui].output(I18n.t(
            "vagrant.box_add_with_version",
            name: name,
            version: version,
            provider: provider))

          # Verify the box we're adding doesn't already exist
          if provider && !env[:box_force]
            box = env[:box_collection].find(
              name, provider, version)
            if box
              raise Errors::BoxAlreadyExists,
                name: name,
                provider: provider,
                version: version
            end
          end

          # Now we have a URL, we have to download this URL.
          box = nil
          begin
            box_url = download(url, env)

            # Add the box!
            box = env[:box_collection].add(
              box_url, name, version,
              force: env[:box_force],
              providers: provider)
          ensure
            # Make sure we delete the temporary file after we add it,
            # unless we were interrupted, in which case we keep it around
            # so we can resume the download later.
            if !@download_interrupted
              @logger.debug("Deleting temporary box: #{box_url}")
              box_url.delete
            end
          end

          env[:ui].success(I18n.t(
            "vagrant.box_added",
            name: box.name, provider: box.provider))

          # Store the added box in the env for future middleware
          env[:box_added] = box

          box
        end

        # Returns the download options for the download.
        #
        # @return [Hash]
        def downloader(url, env)
          temp_path = env[:tmp_path].join("box" + Digest::SHA1.hexdigest(url))
          @logger.info("Downloading box: #{url} => #{temp_path}")

          if File.file?(url) || url !~ /^[a-z0-9]+:.*$/i
            @logger.info("URL is a file or protocol not found and assuming file.")
            file_path = File.expand_path(url)
            file_path = Util::Platform.cygwin_windows_path(file_path)
            url = "file:#{file_path}"
          end

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

          downloader_options = {}
          downloader_options[:ca_cert] = env[:box_download_ca_cert]
          downloader_options[:continue] = true
          downloader_options[:insecure] = env[:box_download_insecure]
          downloader_options[:ui] = env[:ui]
          downloader_options[:client_cert] = env[:box_client_cert]

          Util::Downloader.new(url, temp_path, downloader_options)
        end

        def download(url, env)
          d = downloader(url, env)

          # Download the box to a temporary path. We store the temporary
          # path as an instance variable so that the `#recover` method can
          # access it.
          env[:ui].info(I18n.t(
            "vagrant.actions.box.download.downloading",
            url: url))
          if File.file?(d.destination)
            env[:ui].info(I18n.t("vagrant.actions.box.download.resuming"))
          end

          begin
            d.download!
          rescue Errors::DownloaderInterrupted
            # The downloader was interrupted, so just return, because that
            # means we were interrupted as well.
            @download_interrupted = true
            env[:ui].info(I18n.t("vagrant.actions.box.download.interrupted"))
          rescue Errors::DownloaderError
            # The download failed for some reason, clean out the temp path
            File.unlink(d.destination) if File.file?(d.destination)
            raise
          end

          Pathname.new(d.destination)
        end

        # Tests whether the given URL points to a metadata file or a
        # box file without completely downloading the file.
        #
        # @param [String] url
        # @return [Boolean] true if metadata
        def metadata_url?(url, env)
          d = downloader(url, env)

          # If we're downloading a file, cURL just returns no
          # content-type (makes sense), so we just test if it is JSON
          # by trying to parse JSON!
          uri = URI.parse(d.source)
          if uri.scheme == "file"
            begin
              File.open(uri.opaque, "r") do |f|
                BoxMetadata.new(f)
              end
              return true
            rescue Errors::BoxMetadataMalformed
              return false
            end
          end

          # TODO: do the HEAD request
          output = d.head
          match  = output.scan(/^Content-Type: (.+?)$/).last
          return false if !match
          match.last.chomp == "application/json"
        end
      end
    end
  end
end
