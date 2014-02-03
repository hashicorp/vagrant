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

          url = Array(env[:box_url]).map do |u|
            next u if u =~ /^[a-z0-9]+:.*$/i

            # Expand the path and try to use that, if possible
            p = File.expand_path(u)
            p = Util::Platform.cygwin_windows_path(p)
            next p if File.file?(p)

            u
          end

          # If we received a shorthand URL ("mitchellh/precise64"),
          # then expand it properly.
          expanded = false
          url.each_index do |i|
            next if url[i] !~ /^[^\/]+\/[^\/]+$/

            if !File.file?(url[i])
              server   = Vagrant.server_url
              raise Errors::BoxServerNotSet if !server

              expanded = true
              url[i] = "#{server}/#{url[i]}"
            end
          end

          # Test if any of our URLs point to metadata
          is_metadata_results = url.map do |u|
            begin
              metadata_url?(u, env)
            rescue Errors::DownloaderError => e
              e
            end
          end

          if expanded && url.length == 1
            is_error = is_metadata_results.find do |b|
              b.is_a?(Errors::DownloaderError)
            end

            if is_error
              raise Errors::BoxAddShortNotFound,
                error: is_error.extra_data[:message],
                name: env[:box_url],
                url: url
            end
          end

          is_metadata = is_metadata_results.any? { |b| b === true }
          if is_metadata && url.length > 1
            raise Errors::BoxAddMetadataMultiURL,
              urls: url.join(", ")
          end

          if is_metadata
            add_from_metadata(url.first, env, expanded)
          else
            add_direct(url, env)
          end

          @app.call(env)
        end

        # Adds a box file directly (no metadata component, versioning,
        # etc.)
        #
        # @param [Array<String>] urls
        # @param [Hash] env
        def add_direct(urls, env)
          name = env[:box_name]
          if !name || name == ""
            raise Errors::BoxAddNameRequired
          end

          provider = env[:box_provider]
          provider = Array(provider) if provider

          box_add(
            urls,
            name,
            "0",
            provider,
            nil,
            env)
        end

        # Adds a box given that the URL is a metadata document.
        def add_from_metadata(url, env, expanded)
          original_url = env[:box_url]
          provider = env[:box_provider]
          provider = Array(provider) if provider
          version = env[:box_version]

          env[:ui].output(I18n.t(
            "vagrant.box_loading_metadata",
            name: Array(original_url).first))
          if original_url != url
            env[:ui].detail(I18n.t(
              "vagrant.box_expanding_url", url: url))
          end

          metadata = nil
          begin
            metadata_path = download(url, env, ui: false)

            File.open(metadata_path) do |f|
              metadata = BoxMetadata.new(f)
            end
          rescue Errors::DownloaderError => e
            raise if !expanded
            raise Errors::BoxAddShortNotFound,
              error: e.extra_data[:message],
              name: original_url,
              url: url
          ensure
            metadata_path.delete if metadata_path && metadata_path.file?
          end

          if env[:box_name] && metadata.name != env[:box_name]
            raise Errors::BoxAddNameMismatch,
              actual_name: metadata.name,
              requested_name: env[:box_name]
          end

          metadata_version  = metadata.version(
            version || ">= 0", provider: provider)
          if !metadata_version
            if !provider
              raise Errors::BoxAddNoMatchingVersion,
                constraints: version || ">= 0",
                name: metadata.name,
                url: url,
                versions: metadata.versions.join(", ")
            else
              # TODO: show supported providers
              raise Errors::BoxAddNoMatchingProvider,
                name: metadata.name,
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
          else
            providers = metadata_version.providers.sort

            choice = 0
            options = providers.map do |p|
              choice += 1
              "#{choice}) #{p}"
            end.join("\n")

            # We have more than one provider, ask the user what they want
            choice = env[:ui].ask(I18n.t(
              "vagrant.box_add_choose_provider",
              options: options) + " ", prefix: false)
            choice = choice.to_i if choice
            while !choice || choice <= 0 || choice > providers.length
              choice = env[:ui].ask(I18n.t(
                "vagrant.box_add_choose_provider_again") + " ",
                prefix: false)
              choice = choice.to_i if choice
            end

            metadata_provider = metadata_version.provider(
              providers[choice-1])
          end

          box_add(
            [metadata_provider.url],
            metadata.name,
            metadata_version.version,
            metadata_provider.name,
            url,
            env)
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
        # @param [Array<String>] urls
        # @param [String] name
        # @param [String] version
        # @param [String] provider
        # @param [Hash] env
        # @return [Box]
        def box_add(urls, name, version, provider, md_url, env, **opts)
          env[:ui].output(I18n.t(
            "vagrant.box_add_with_version",
            name: name,
            version: version,
            providers: Array(provider).join(", ")))

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
            box_url = nil

            urls.each do |url|
              begin
                box_url = download(url, env)
                break
              rescue Errors::DownloaderError => e
                env[:ui].error(I18n.t(
                  "vagrant.box_download_error",  message: e.message))
                box_url = nil
              end
            end

            # Add the box!
            box = env[:box_collection].add(
              box_url, name, version,
              force: env[:box_force],
              metadata_url: md_url,
              providers: provider)
          ensure
            # Make sure we delete the temporary file after we add it,
            # unless we were interrupted, in which case we keep it around
            # so we can resume the download later.
            if !@download_interrupted
              @logger.debug("Deleting temporary box: #{box_url}")
              box_url.delete if box_url
            end
          end

          env[:ui].success(I18n.t(
            "vagrant.box_added",
            name: box.name,
            version: box.version,
            provider: box.provider))

          # Store the added box in the env for future middleware
          env[:box_added] = box

          box
        end

        # Returns the download options for the download.
        #
        # @return [Hash]
        def downloader(url, env, **opts)
          opts[:ui] = true if !opts.has_key?(:ui)

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
          downloader_options[:client_cert] = env[:box_client_cert]
          downloader_options[:ui] = env[:ui] if opts[:ui]

          Util::Downloader.new(url, temp_path, downloader_options)
        end

        def download(url, env, **opts)
          opts[:ui] = true if !opts.has_key?(:ui)

          d = downloader(url, env, **opts)

          # Download the box to a temporary path. We store the temporary
          # path as an instance variable so that the `#recover` method can
          # access it.
          if opts[:ui]
            env[:ui].detail(I18n.t(
              "vagrant.box_downloading",
              url: url))
            if File.file?(d.destination)
              env[:ui].info(I18n.t("vagrant.actions.box.download.resuming"))
            end
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
          d = downloader(url, env, ui: false)

          # If we're downloading a file, cURL just returns no
          # content-type (makes sense), so we just test if it is JSON
          # by trying to parse JSON!
          uri = URI.parse(d.source)
          if uri.scheme == "file"
            url = uri.path
            url ||= uri.opaque

            begin
              File.open(url, "r") do |f|
                BoxMetadata.new(f)
              end
              return true
            rescue Errors::BoxMetadataMalformed
              return false
            rescue Errno::ENOENT
              return false
            end
          end

          output = d.head
          match  = output.scan(/^Content-Type: (.+?)$/).last
          return false if !match
          match.last.chomp == "application/json"
        end
      end
    end
  end
end
