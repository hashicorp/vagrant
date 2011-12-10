module Vagrant
  module Action
    module Box
      class Download
        BASENAME = "box"

        include Util

        attr_reader :temp_path

        def initialize(app, env)
          @app = app
          @env = env
          @env["download.classes"] ||= []
          @env["download.classes"] += [Downloaders::HTTP, Downloaders::File]
          @downloader = nil
        end

        def call(env)
          @env = env

          download if instantiate_downloader
          @app.call(@env)

          recover(env) # called in both cases to cleanup workspace
        end

        def instantiate_downloader
          # Assign to a temporary variable since this is easier to type out,
          # since it is used so many times.
          classes = @env["download.classes"]

          # Find the class to use.
          classes.each_index do |i|
            klass = classes[i]

            # Use the class if it matches the given URI or if this
            # is the last class...
            if classes.length == (i + 1) || klass.match?(@env["box_url"])
              @env[:ui].info I18n.t("vagrant.actions.box.download.with", :class => klass.to_s)
              @downloader = klass.new(@env[:ui])
              break
            end
          end

          # This line should never be reached, but we'll keep this here
          # just in case for now.
          raise Errors::BoxDownloadUnknownType if !@downloader

          @downloader.prepare(@env["box_url"])
          true
        end

        def download
          with_tempfile do |tempfile|
            download_to(tempfile)
            @temp_path = @env["download.temp_path"] = tempfile.path
          end
        end

        def recover(env)
          if temp_path && File.exist?(temp_path)
            env[:ui].info I18n.t("vagrant.actions.box.download.cleaning")
            File.unlink(temp_path)
          end
        end

        def with_tempfile
          File.open(box_temp_path, Platform.tar_file_options) do |tempfile|
            yield tempfile
          end
        end

        def box_temp_path
          @env[:tmp_path].join(BASENAME + Time.now.to_i.to_s)
        end

        def download_to(f)
          @downloader.download!(@env["box_url"], f)
        end
      end
    end
  end
end
