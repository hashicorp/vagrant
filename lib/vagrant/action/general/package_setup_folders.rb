require "fileutils"
require_relative "package"

module Vagrant
  module Action
    module General
      class PackageSetupFolders
        include Vagrant::Util::Presence

        def initialize(app, env)
          @app = app
        end

        def call(env)
          env["package.output"] ||= "package.box"
          env["package.directory"] ||= Dir.mktmpdir("vagrant-package-", env[:tmp_path])

          # Match up a couple environmental variables so that the other parts of
          # Vagrant will do the right thing.
          env["export.temp_dir"] = env["package.directory"]

          Vagrant::Action::General::Package.validate!(
              env["package.output"], env["package.directory"])

          @app.call(env)
        end

        def recover(env)
          dir = env["package.directory"]
          if File.exist?(dir)
            FileUtils.rm_rf(dir)
          end
        end
      end
    end
  end
end
