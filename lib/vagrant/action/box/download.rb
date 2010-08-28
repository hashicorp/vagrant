module Vagrant
  class Action
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
          @env["download.classes"].each do |klass|
            if klass.match?(@env["box"].uri)
              @env.ui.info "vagrant.actions.box.download.with", :class => klass.to_s
              @downloader = klass.new(@env)
            end
          end

          raise Errors::BoxDownloadUnknownType.new if !@downloader

          @downloader.prepare(@env["box"].uri)
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
            env.ui.info "vagrant.actions.box.download.cleaning"
            File.unlink(temp_path)
          end
        end

        def with_tempfile
          File.open(box_temp_path, Platform.tar_file_options) do |tempfile|
            yield tempfile
          end
        end

        def box_temp_path
          File.join(@env.env.tmp_path, BASENAME + Time.now.to_i.to_s)
        end

        def download_to(f)
          @env.ui.info "vagrant.actions.box.download.copying"
          @downloader.download!(@env["box"].uri, f)
        end
      end
    end
  end
end
