require "fileutils"
require "log4r"
require "json"

module VagrantPlugins
  module HyperV
    module Action
      class Import

        VALID_HD_EXTENSIONS = [".vhd".freeze, ".vhdx".freeze].freeze

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::hyperv::import")
        end

        def call(env)
          vm_dir = env[:machine].box.directory.join("Virtual Machines")
          hd_dir = env[:machine].box.directory.join("Virtual Hard Disks")
          controllers = env[:machine].provider_config.controllers
          if !vm_dir.directory? || !hd_dir.directory?
            @logger.error("Required virtual machine directory not found!")
            raise Errors::BoxInvalid, name: env[:machine].name
          end

          valid_config_ext = [".xml"]
          if env[:machine].provider.driver.has_vmcx_support?
            valid_config_ext << ".vmcx"
          end

          config_path = nil
          vm_dir.each_child do |file|
            if valid_config_ext.include?(file.extname.downcase)
              config_path = file
              break
            end
          end

          if !config_path
            @logger.error("Failed to locate box configuration path")
            raise Errors::BoxInvalid, name: env[:machine].name
          else
            @logger.info("Found box configuration path: #{config_path}")
          end

          image_path = nil
          hd_dir.each_child do |file|
            if VALID_HD_EXTENSIONS.include?(file.extname.downcase)
              image_path = file
              break
            end
          end

          if !image_path
            @logger.error("Failed to locate box image path")
            raise Errors::BoxInvalid, name: env[:machine].name
          else
            @logger.info("Found box image path: #{image_path}")
          end

          env[:ui].output("Importing a Hyper-V instance")
          dest_path = env[:machine].data_dir.join("Virtual Hard Disks").join(image_path.basename).to_s

          disks_to_create = []
          data_dir = env[:machine].data_dir
          # This can happen when creating new on up.
          controllers.delete_if &:empty?
          
          controllers.each { |controller|
            next_is_size = false
            disk_name = ''
            controller[:disks].each { |i|
              if !next_is_size
                if File.file?(i)
                  create_disk = false 
                  filename_for_disk = i
                  next_is_size = false
                
                  @logger.error("Attaching disks is not implemented yet")
                else
                  create_disk = true
                  disk_name = i
                  disk_name = data_dir.join("#{disk_name}.vhdx").to_s.gsub("/", "\\")
                  next_is_size = true
                end
              else
                disks_to_create << { name: disk_name, size: i}
              end
            }
          }
          disks_to_create_json = disks_to_create.to_json.to_s.gsub('"', '"""')

          options = {
            "VMConfigFile" => Vagrant::Util::Platform.wsl_to_windows_path(config_path).gsub("/", "\\"),
            "DestinationPath" => Vagrant::Util::Platform.wsl_to_windows_path(dest_path).gsub("/", "\\"),
            "DataPath" => Vagrant::Util::Platform.wsl_to_windows_path(env[:machine].data_dir).gsub("/", "\\"),
            "LinkedClone" => !!env[:machine].provider_config.linked_clone,
            "SourcePath" => Vagrant::Util::Platform.wsl_to_windows_path(image_path).gsub("/", "\\"),
            "VMName" => env[:machine].provider_config.vmname,
            "DisksToCreate" => disks_to_create_json,
          }


          env[:ui].detail("Creating and registering the VM...")
          server = env[:machine].provider.driver.import(options)

          env[:ui].detail("Successfully imported VM")
          env[:machine].id = server["id"]
          @app.call(env)
        end
      end
    end
  end
end
