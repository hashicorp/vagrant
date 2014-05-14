require "fileutils"

require "log4r"

module VagrantPlugins
  module HyperV
    module Action
      class Import
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::hyperv::import")
        end

        def call(env)
          vm_dir = env[:machine].box.directory.join("Virtual Machines")
          hd_dir = env[:machine].box.directory.join("Virtual Hard Disks")

          if !vm_dir.directory? || !hd_dir.directory?
            raise Errors::BoxInvalid
          end

          config_path = nil
          vm_dir.each_child do |f|
            if f.extname.downcase == ".xml"
              config_path = f
              break
            end
          end

          vhdx_path = nil
          hd_dir.each_child do |f|
            if f.extname.downcase == ".vhdx"
              vhdx_path = f
              break
            end
          end

          if !config_path || !vhdx_path
            raise Errors::BoxInvalid
          end

          env[:ui].output("Importing a Hyper-V instance")

          env[:ui].detail("Cloning virtual hard drive...")
          source_path = vhdx_path.to_s
          dest_path   = env[:machine].data_dir.join("disk.vhdx").to_s
          FileUtils.cp(source_path, dest_path)
          vhdx_path = dest_path

          # We have to normalize the paths to be Windows paths since
          # we're executing PowerShell.
          options = {
            vm_xml_config:  config_path.to_s.gsub("/", "\\"),
            vhdx_path:      vhdx_path.to_s.gsub("/", "\\")
          }

          env[:ui].detail("Creating and registering the VM...")
          server = env[:machine].provider.driver.import(options)
          env[:ui].detail("Successfully imported a VM with name: #{server['name']}")
          env[:machine].id = server["id"]
          @app.call(env)
        end
      end
    end
  end
end
