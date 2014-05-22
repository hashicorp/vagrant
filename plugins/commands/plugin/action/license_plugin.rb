require "fileutils"
require "pathname"
require "rubygems"
require "set"

require "log4r"

module VagrantPlugins
  module CommandPlugin
    module Action
      # This middleware licenses a plugin by copying the license file to
      # the proper place.
      class LicensePlugin
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::plugins::plugincommand::license")
        end

        def call(env)
          # Verify the license file exists
          license_file = Pathname.new(env[:plugin_license_path])
          if !license_file.file?
            raise Vagrant::Errors::PluginInstallLicenseNotFound,
              name: env[:plugin_name],
              path: license_file.to_s
          end

          # Copy it in.
          final_path = env[:home_path].join("license-#{env[:plugin_name]}.lic")
          @logger.info("Copying license from: #{license_file}")
          @logger.info("Copying license to: #{final_path}")
          env[:ui].info(I18n.t("vagrant.commands.plugin.installing_license",
                               name: env[:plugin_name]))
          FileUtils.cp(license_file, final_path)

          # Installed!
          env[:ui].success(I18n.t("vagrant.commands.plugin.installed_license",
                                 name: env[:plugin_name]))

          @app.call(env)
        end
      end
    end
  end
end
