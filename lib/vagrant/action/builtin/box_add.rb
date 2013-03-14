require "log4r"

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
          # Instantiate the downloader
          downloader = download_klass(env[:box_url]).new(env[:ui])
          env[:ui].info I18n.t("vagrant.actions.box.download.with",
                               :class => downloader.class.to_s)

          # Download the box to a temporary path. We store the temporary
          # path as an instance variable so that the `#recover` method can
          # access it.
          @temp_path = env[:tmp_path].join("box" + Time.now.to_i.to_s)
          @logger.info("Downloading box to: #{@temp_path}")
          File.open(@temp_path, Vagrant::Util::Platform.tar_file_options) do |f|
            downloader.download!(env[:box_url], f)
          end

          # Add the box
          env[:ui].info I18n.t("vagrant.actions.box.add.adding", :name => env[:box_name])
          added_box = nil
          begin
            added_box = env[:box_collection].add(
              @temp_path, env[:box_name], env[:box_provider], env[:box_force])
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

        def download_klass(url)
          # This is hardcoded for now. In the future I'd like to make this
          # pluginnable as well.
          classes = [Downloaders::HTTP, Downloaders::File]

          # Find the class to use.
          classes.each_index do |i|
            klass = classes[i]

            # Use the class if it matches the given URI or if this
            # is the last class...
            return klass if classes.length == (i + 1) || klass.match?(url)
          end

          # If no downloader knows how to download this file, then we
          # raise an exception.
          raise Errors::BoxDownloadUnknownType
        end

        def recover(env)
          if @temp_path && File.exist?(@temp_path)
            env[:ui].info I18n.t("vagrant.actions.box.download.cleaning")
            File.unlink(@temp_path)
          end
        end
      end
    end
  end
end
