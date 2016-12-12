require "json"

#require 'vagrant/util/template_renderer'

module VagrantPlugins
  module HyperV
    module Action
      class PackageMetadataJson
        # For TemplateRenderer
        include Vagrant::Util

        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env
          create_metadata
          @app.call(env)
        end

        # This method creates a metadata.json file to tell vagrant this is a
        # Hyper V box
        def create_metadata
          File.open(File.join(@env["export.temp_dir"], "metadata.json"), "w") do |f|
            f.write(JSON.generate({
              provider: "hyperv"
            }))
          end
        end
      end
    end
  end
end
