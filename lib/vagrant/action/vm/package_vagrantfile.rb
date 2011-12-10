module Vagrant
  module Action
    module VM
      # Puts a generated Vagrantfile into the package directory so that
      # it can be included in the package.
      class PackageVagrantfile
        include Util

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          @env = env
          create_vagrantfile
          @app.call(env)
        end

        # This method creates the auto-generated Vagrantfile at the root of the
        # box. This Vagrantfile contains the MAC address so that the user doesn't
        # have to worry about it.
        def create_vagrantfile
          File.open(File.join(@env["export.temp_dir"], "Vagrantfile"), "w") do |f|
            f.write(TemplateRenderer.render("package_Vagrantfile", {
              :base_mac => @env["vm"].vm.network_adapters.first.mac_address
            }))
          end
        end
      end
    end
  end
end
