module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class SetupPackageFiles
        def initialize(app, env)
          @app = app

          env["package.include"] ||= []
          env["package.vagrantfile"] ||= nil
        end

        def call(env)
          files = {}
          env["package.include"].each do |file|
            source = Pathname.new(file)
            dest   = nil

            # If the source is relative then we add the file as-is to the include
            # directory. Otherwise, we copy only the file into the root of the
            # include directory. Kind of strange, but seems to match what people
            # expect based on history.
            if source.relative?
              dest = source
            else
              dest = source.basename
            end

            # Assign the mapping
            files[file] = dest
          end

          if env["package.vagrantfile"]
            # Vagrantfiles are treated special and mapped to a specific file
            files[env["package.vagrantfile"]] = "_Vagrantfile"
          end

          # Verify the mapping
          files.each do |from, _|
            raise Vagrant::Errors::PackageIncludeMissing,
              file: from if !File.exist?(from)
          end

          # Save the mapping
          env["package.files"] = files

          @app.call(env)
        end
      end
    end
  end
end
