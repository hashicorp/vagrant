require "fileutils"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      # Cleans up the VirtualBox machine folder for any ".xml-prev"
      # files which VirtualBox may have left over. This is a bug in
      # VirtualBox. As soon as this is fixed, this middleware can and
      # will be removed.
      class CleanMachineFolder
        def initialize(app, env)
          @app = app
        end

        def call(env)
          clean_machine_folder(env[:machine].provider.driver.read_machine_folder)
          @app.call(env)
        end

        def clean_machine_folder(machine_folder)
          folder = File.join(machine_folder, "*")

          # Small safeguard against potentially unwanted rm-rf, since the default
          # machine folder will typically always be greater than 10 characters long.
          # For users with it < 10, out of luck?
          return if folder.length < 10

          Dir[folder].each do |f|
            next unless File.directory?(f)

            keep = Dir["#{f}/**/*"].find do |d|
              # Find a file that doesn't have ".xml-prev" as the suffix,
              # which signals that we want to keep this folder
              File.file?(d) && !(File.basename(d) =~ /\.vbox-prev$/)
            end

            FileUtils.rm_rf(f) if !keep
          end
        end
      end
    end
  end
end
