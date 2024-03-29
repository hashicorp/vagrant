# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require 'vagrant/util/template_renderer'

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class PackageVagrantfile
        # For TemplateRenderer
        include Vagrant::Util

        def initialize(app, env)
          @app = app
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
              base_mac: @env[:machine].provider.driver.read_mac_address
            }))
          end
        end
      end
    end
  end
end
