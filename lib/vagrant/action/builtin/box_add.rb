require "digest/sha1"
require "log4r"

require "vagrant/util/downloader"
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
          @temp_path = env[:tmp_path].join("box" + Digest::SHA1.hexdigest(env[:box_url]))
          @logger.info("Downloading box to: #{@temp_path}")

          url = env[:box_url]
          if File.file?(url) || url !~ /^[a-z0-9]+:.*$/i
            @logger.info("URL is a file or protocol not found and assuming file.")
            file_path = File.expand_path(url)
            file_path = Util::Platform.cygwin_windows_path(file_path)
            url = "file:#{file_path}"
          end

          downloader_options = {}
          downloader_options[:continue] = true
          downloader_options[:insecure] = env[:box_download_insecure]
          downloader_options[:ui] = env[:ui]

          # If the temporary path exists, verify it is not too old. If its
          # too old, delete it first because the data may have changed.
          if @temp_path.file?
            delete = false
            if env[:box_clean]
              @logger.info("Cleaning existing temp box file.")
              delete = true
            elsif @temp_path.mtime.to_i < (Time.now.to_i - 6 * 60 * 60)
              @logger.info("Existing temp file is too old. Removing.")
              delete = true
            end

            @temp_path.unlink if delete
          end

          # Download the box to a temporary path. We store the temporary
          # path as an instance variable so that the `#recover` method can
          # access it.
          env[:ui].info(I18n.t("vagrant.actions.box.download.downloading"))

          if @temp_path.file?
            env[:ui].info(I18n.t("vagrant.actions.box.download.resuming"))
          end

          begin
            downloader = Util::Downloader.new(url, @temp_path, downloader_options)
            downloader.download!
          rescue Errors::DownloaderInterrupted
            # The downloader was interrupted, so just return, because that
            # means we were interrupted as well.
            @download_interrupted = true
            env[:ui].info(I18n.t("vagrant.actions.box.download.interrupted"))
            return
          end

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

          # Add the box
          env[:ui].info I18n.t("vagrant.actions.box.add.adding", :name => env[:box_name])
          added_box = nil
          begin
            added_box = env[:box_collection].add(
              @temp_path, env[:box_name], box_formats, env[:box_force])
          rescue Vagrant::Errors::BoxUpgradeRequired
            # Upgrade the box
            env[:box_collection].upgrade(env[:box_name])

            # Try adding it again
            retry
          end

          # Call the 'recover' method in all cases to clean up the
          # downloaded temporary file.
          recover(env)

          # Success, we added a box!
          env[:ui].success(
            I18n.t("vagrant.actions.box.add.added", name: added_box.name, provider: added_box.provider))

          # Carry on!
          @app.call(env)
        end

        def recover(env)
          if @temp_path && File.exist?(@temp_path) && !@download_interrupted
            File.unlink(@temp_path)
          end
        end
      end
    end
  end
end
