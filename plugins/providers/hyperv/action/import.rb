#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

require "log4r"
module VagrantPlugins
  module HyperV
    module Action
      class Import
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::hyperv::connection")
        end

        def call(env)
          box_directory = env[:machine].box.directory.to_s
          path = Pathname.new(box_directory.to_s + '/Virtual Machines')
          config_path = ""
          path.each_child do |f|
            config_path = f.to_s if f.extname.downcase == ".xml"
          end

          path = Pathname.new(box_directory.to_s + '/Virtual Hard Disks')
          vhdx_path = ""
          path.each_child do |f|
            vhdx_path = f.to_s if f.extname.downcase == ".vhdx"
          end

          options = {
            vm_xml_config:  config_path.gsub("/", "\\"),
            vhdx_path: vhdx_path.gsub("/", "\\")
          }

          env[:ui].info "Importing a Hyper-V instance"
          begin
            server = env[:machine].provider.driver.execute('import_vm.ps1', options)
          rescue Error::SubprocessError => e
            env[:ui].info e.message
            return
          end
          env[:ui].info "Successfully imported a VM with name   #{server['name']}"
          env[:machine].id = server["id"]
          @app.call(env)
        end
      end
    end
  end
end
