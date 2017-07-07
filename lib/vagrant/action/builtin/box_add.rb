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
        # This is the size in bytes that if a file exceeds, is considered
        # to NOT be metadata.
        METADATA_SIZE_LIMIT = 20971520

        # This is the amount of time to "resume" downloads if a partial box
        # file already exists.
        RESUME_DELAY = 24 * 60 * 60

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::box_add")
        end

        def call(env)
          @download_interrupted = false

          unless env[:box_name].nil?
            begin
              if URI.parse(env[:box_name]).kind_of?(URI::HTTP)
                env[:ui].warn(I18n.t("vagrant.box_add_url_warn"))
              end
            rescue URI::InvalidURIError
              # do nothing
            end
          end

          url = Array(env[:box_url]).map do |u|
            u = u.gsub("\\", "/")
            if Util::Platform.windows? && u =~ /^[a-z]:/i
              # On Windows, we need to be careful about drive letters
              u = "file:///#{URI.escape(u)}"
            end

            if u =~ /^[a-z0-9]+:.*$/i && !u.start_with?("file://")
              # This is not a file URL... carry on
              next u
            end

            # Expand the path and try to use that, if possible
            p = File.expand_path(URI.unescape(u.gsub(/^file:\/\//, "")))
            p = Util::Platform.cygwin_windows_path(p)
            next "file://#{URI.escape(p.gsub("\\", "/"))}" if File.file?(p)

            u
          end

          # If we received a shorthand URL ("mitchellh/precise64"),
          # then expand it properly.
          expanded = false
          url.each_index do |i|
            next if url[i] !~ /^[^\/]+\/[^\/]+$/

            if !File.file?(url[i])
              server = Vagrant.server_url env[:box_server_url]
              raise Errors::BoxServerNotSet if !server

              expanded = true
              url[i] = "#{server}/#{url[i]}"
            end
          end

          # Call the hook to transform URLs into authenticated URLs.
          # In the case we don't have a plugin that does this, then it
          # will just return the same URLs.
          hook_env    = env[:hook].call(
            :authenticate_box_url, box_urls: url.dup)
          authed_urls = hook_env[:box_urls]
          if !authed_urls || authed_urls.length != url.length
            raise "Bad box authentication hook, did not generate proper results."
          end

          # Test if any of our URLs point to metadata
          is_metadata_results = authed_urls.map do |u|
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
            url = [url.first, authed_urls.first]
            add_from_metadata(url, env, expanded)
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
          env[:ui].output(I18n.t("vagrant.box_adding_direct"))

          name = env[:box_name]
          if !name || name == ""
            raise Errors::BoxAddNameRequired
          end

          if env[:box_version]
            raise Errors::BoxAddDirectVersion
          end

          provider = env[:box_provider]
          provider = Array(provider) if provider

          box_add(
            urls,
            name,
            "0",
            provider,
            nil,
            env,
            checksum: env[:box_checksum],
            checksum_type: env[:box_checksum_type],
          )
        end

        # Adds a box given that the URL is a metadata document.
        #
        # @param [String | Array<String>] url The URL of the metadata for
        #   the box to add. If this is an array, then it must be a two-element
        #   array where the first element is the original URL and the second
        #   element is an authenticated URL.
        # @param [Hash] env
        # @param [Bool] expanded True if the metadata URL was expanded with
        #   a Atlas server URL.
        def add_from_metadata(url, env, expanded)
          original_url = env[:box_url]
          provider = env[:box_provider]
          provider = Array(provider) if provider
          version = env[:box_version]

          authenticated_url = url
          if url.is_a?(Array)
            # We have both a normal URL and "authenticated" URL. Split
            # them up.
            authenticated_url = url[1]
            url               = url[0]
          end

          display_original_url = Util::CredentialScrubber.scrub(Array(original_url).first)
          display_url = Util::CredentialScrubber.scrub(url)

          env[:ui].output(I18n.t(
            "vagrant.box_loading_metadata",
            name: display_original_url))
          if original_url != url
            env[:ui].detail(I18n.t(
              "vagrant.box_expanding_url", url: display_url))
          end

          metadata = nil
          begin
            metadata_path = download(
              authenticated_url, env, json: true, ui: false)
            return if @download_interrupted

            File.open(metadata_path) do |f|
              metadata = BoxMetadata.new(f)
            end
          rescue Errors::DownloaderError => e
            raise if !expanded
            raise Errors::BoxAddShortNotFound,
              error: e.extra_data[:message],
              name: display_original_url,
              url: display_url
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
            if provider && !metadata.version(">= 0", provider: provider)
              raise Errors::BoxAddNoMatchingProvider,
                name: metadata.name,
                requested: provider,
                url: display_url
            else
              raise Errors::BoxAddNoMatchingVersion,
                constraints: version || ">= 0",
                name: metadata.name,
                url: display_url,
                versions: metadata.versions.join(", ")
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

          provider_url = metadata_provider.url
          if provider_url != authenticated_url
            # Authenticate the provider URL since we're using auth
            hook_env    = env[:hook].call(:authenticate_box_url, box_urls: [provider_url])
            authed_urls = hook_env[:box_urls]
            if !authed_urls || authed_urls.length != 1
              raise "Bad box authentication hook, did not generate proper results."
            end
            provider_url = authed_urls[0]
          end

          box_add(
            [[provider_url, metadata_provider.url]],
            metadata.name,
            metadata_version.version,
            metadata_provider.name,
            url,
            env,
            checksum: metadata_provider.checksum,
            checksum_type: metadata_provider.checksum_type,
          )
        end

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
              show_url = nil
              if url.is_a?(Array)
                show_url = url[1]
                url      = url[0]
              end

              begin
                box_url = download(url, env, show_url: show_url)
                break
              rescue Errors::DownloaderError => e
                # If we don't have multiple URLs, just raise the error
                raise if urls.length == 1

                env[:ui].error(I18n.t(
                  "vagrant.box_download_error",  message: e.message))
                box_url = nil
              end
            end

            if opts[:checksum] && opts[:checksum_type]
              env[:ui].detail(I18n.t("vagrant.actions.box.add.checksumming"))
              validate_checksum(
                opts[:checksum_type], opts[:checksum], box_url)
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
              begin
                box_url.delete if box_url
              rescue Errno::ENOENT
                # Not a big deal, the temp file may not actually exist
              end
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
          opts[:ui] = true if !opts.key?(:ui)

          temp_path = env[:tmp_path].join("box" + Digest::SHA1.hexdigest(url))
          @logger.info("Downloading box: #{url} => #{temp_path}")

          if File.file?(url) || url !~ /^[a-z0-9]+:.*$/i
            @logger.info("URL is a file or protocol not found and assuming file.")
            file_path = File.expand_path(url)
            file_path = Util::Platform.cygwin_windows_path(file_path)
            file_path = file_path.gsub("\\", "/")
            file_path = "/#{file_path}" if !file_path.start_with?("/")
            url = "file://#{file_path}"
          end

          # If the temporary path exists, verify it is not too old. If its
          # too old, delete it first because the data may have changed.
          if temp_path.file?
            delete = false
            if env[:box_clean]
              @logger.info("Cleaning existing temp box file.")
              delete = true
            elsif temp_path.mtime.to_i < (Time.now.to_i - RESUME_DELAY)
              @logger.info("Existing temp file is too old. Removing.")
              delete = true
            end

            temp_path.unlink if delete
          end

          downloader_options = {}
          downloader_options[:ca_cert] = env[:box_download_ca_cert]
          downloader_options[:ca_path] = env[:box_download_ca_path]
          downloader_options[:continue] = true
          downloader_options[:insecure] = env[:box_download_insecure]
          downloader_options[:client_cert] = env[:box_download_client_cert]
          downloader_options[:headers] = ["Accept: application/json"] if opts[:json]
          downloader_options[:ui] = env[:ui] if opts[:ui]
          downloader_options[:location_trusted] = env[:box_download_location_trusted]

          Util::Downloader.new(url, temp_path, downloader_options)
        end

        def download(url, env, **opts)
          opts[:ui] = true if !opts.key?(:ui)

          d = downloader(url, env, **opts)

          # Download the box to a temporary path. We store the temporary
          # path as an instance variable so that the `#recover` method can
          # access it.
          if opts[:ui]
            show_url = opts[:show_url]
            show_url ||= url
            display_url = Util::CredentialScrubber.scrub(show_url)

            translation = "vagrant.box_downloading"

            # Adjust status message when 'downloading' a local box.
            if show_url.start_with?("file://")
              translation = "vagrant.box_unpacking"
            end

            env[:ui].detail(I18n.t(
              translation,
              url: display_url))
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
          end

          Pathname.new(d.destination)
        end

        # Tests whether the given URL points to a metadata file or a
        # box file without completely downloading the file.
        #
        # @param [String] url
        # @return [Boolean] true if metadata
        def metadata_url?(url, env)
          d = downloader(url, env, json: true, ui: false)

          # If we're downloading a file, cURL just returns no
          # content-type (makes sense), so we just test if it is JSON
          # by trying to parse JSON!
          uri = URI.parse(d.source)
          if uri.scheme == "file"
            url = uri.path
            url ||= uri.opaque
            #7570 Strip leading slash left in front of drive letter by uri.path
            Util::Platform.windows? && url.gsub!(/^\/([a-zA-Z]:)/, '\1')
            url = URI.unescape(url)

            begin
              File.open(url, "r") do |f|
                if f.size > METADATA_SIZE_LIMIT
                  # Quit early, don't try to parse the JSON of gigabytes
                  # of box files...
                  return false
                end

                BoxMetadata.new(f)
              end
              return true
            rescue Errors::BoxMetadataMalformed
              return false
            rescue Errno::EINVAL
              # Actually not sure what causes this, but its always
              # in a case that isn't true.
              return false
            rescue Errno::EISDIR
              return false
            rescue Errno::ENOENT
              return false
            end
          end

          # If this isn't HTTP, then don't do the HEAD request
          if !uri.scheme.downcase.start_with?("http")
            @logger.info("not checking metadata since box URI isn't HTTP")
            return false
          end

          output = d.head
          match  = output.scan(/^Content-Type: (.+?)$/i).last
          return false if !match
          !!(match.last.chomp =~ /application\/json/)
        end

        def validate_checksum(checksum_type, checksum, path)
          checksum_klass = case checksum_type.to_sym
          when :md5
            Digest::MD5
          when :sha1
            Digest::SHA1
          when :sha256
            Digest::SHA2
          else
            raise Errors::BoxChecksumInvalidType,
              type: checksum_type.to_s
          end

          @logger.info("Validating checksum with #{checksum_klass}")
          @logger.info("Expected checksum: #{checksum}")

          actual = FileChecksum.new(path, checksum_klass).checksum
          if actual.casecmp(checksum) != 0
            raise Errors::BoxChecksumMismatch,
              actual: actual,
              expected: checksum
          end
        end
      end
    end
  end
end
