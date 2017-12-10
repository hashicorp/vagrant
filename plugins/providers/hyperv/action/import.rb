require "fileutils"

require "log4r"

module VagrantPlugins
  module HyperV
    module Action
      class Import
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::hyperv::import")
        end

        def call(env)
          vm_dir = env[:machine].box.directory.join("Virtual Machines")
          hd_dir = env[:machine].box.directory.join("Virtual Hard Disks")
          memory = env[:machine].provider_config.memory
          maxmemory = env[:machine].provider_config.maxmemory
          cpus = env[:machine].provider_config.cpus
          vmname = env[:machine].provider_config.vmname
          differencing_disk = env[:machine].provider_config.differencing_disk
          auto_start_action = env[:machine].provider_config.auto_start_action
          auto_stop_action = env[:machine].provider_config.auto_stop_action
          enable_virtualization_extensions = env[:machine].provider_config.enable_virtualization_extensions
          vm_integration_services = env[:machine].provider_config.vm_integration_services

          env[:ui].output("Configured Dynamic memory allocation, maxmemory is #{maxmemory}") if maxmemory
          env[:ui].output("Configured startup memory is #{memory}") if memory
          env[:ui].output("Configured cpus number is #{cpus}") if cpus
          env[:ui].output("Configured enable virtualization extensions is #{enable_virtualization_extensions}") if enable_virtualization_extensions
          env[:ui].output("Configured vmname is #{vmname}") if vmname
          env[:ui].output("Configured differencing disk instead of cloning") if differencing_disk
          env[:ui].output("Configured automatic start action is #{auto_start_action}") if auto_start_action
          env[:ui].output("Configured automatic stop action is #{auto_stop_action}") if auto_stop_action

          if !vm_dir.directory? || !hd_dir.directory?
            raise Errors::BoxInvalid
          end

          config_path = nil
          config_type = nil
          vm_dir.each_child do |f|
            if f.extname.downcase == '.xml'
              @logger.debug("Found XML config...")
              config_path = f
              config_type = 'xml'
              break
            end
          end

          vmcx_support = env[:machine].provider.driver.execute("has_vmcx_support.ps1", {})['result']
          if vmcx_support
            vm_dir.each_child do |f|
              if f.extname.downcase == '.vmcx'
                @logger.debug("Found VMCX config and support...")
                config_path = f
                config_type = 'vmcx'
                break
              end
            end
          end

          image_path = nil
          image_ext = nil
          image_filename = nil
          hd_dir.each_child do |f|
            if %w{.vhd .vhdx}.include?(f.extname.downcase)
              image_path = f
              image_ext = f.extname.downcase
              image_filename = File.basename(f, image_ext)
              break
            end
          end

          if !config_path || !image_path
            raise Errors::BoxInvalid
          end

          env[:ui].output("Importing a Hyper-V instance")

          switches = env[:machine].provider.driver.execute("get_switches.ps1", {})
          raise Errors::NoSwitches if switches.empty?

          switch = nil
          env[:machine].config.vm.networks.each do |type, opts|
            next if type != :public_network && type != :private_network

            switchToFind = opts[:bridge]

            if switchToFind
              puts "Looking for switch with name: #{switchToFind}"
              switch = switches.find { |s| s["Name"].downcase == switchToFind.downcase }["Name"]
              puts "Found switch: #{switch}"
            end
          end

          if switch.nil?
            if switches.length > 1
              env[:ui].detail(I18n.t("vagrant_hyperv.choose_switch") + "\n ")
              switches.each_index do |i|
                switch = switches[i]
                env[:ui].detail("#{i+1}) #{switch["Name"]}")
              end
              env[:ui].detail(" ")

              switch = nil
              while !switch
                switch = env[:ui].ask("What switch would you like to use? ")
                next if !switch
                switch = switch.to_i - 1
                switch = nil if switch < 0 || switch >= switches.length
              end
              switch = switches[switch]["Name"]
            else
              switch = switches[0]["Name"]
            end
          end

          env[:ui].detail("Cloning virtual hard drive...")
          source_path = image_path.to_s
          dest_path = env[:machine].data_dir.join("Virtual Hard Disks").join("#{image_filename}#{image_ext}").to_s

          # Still hard copy the disk of old XML configurations
          if config_type == 'xml'
            if differencing_disk
              env[:machine].provider.driver.execute("clone_vhd.ps1", {Source: source_path, Destination: dest_path})
            else
              FileUtils.mkdir_p(env[:machine].data_dir.join("Virtual Hard Disks"))
              FileUtils.cp(source_path, dest_path)
            end
          end
          image_path = dest_path

          # We have to normalize the paths to be Windows paths since
          # we're executing PowerShell.
          options = {
              vm_config_file: config_path.to_s.gsub("/", "\\"),
              vm_config_type: config_type,
              source_path:    source_path.to_s,
              dest_path:      dest_path,
              data_path:      env[:machine].data_dir.to_s.gsub("/", "\\")
          }
          options[:switchname] = switch if switch
          options[:memory] = memory if memory
          options[:maxmemory] = maxmemory if maxmemory
          options[:cpus] = cpus if cpus
          options[:vmname] = vmname if vmname
          options[:auto_start_action] = auto_start_action if auto_start_action
          options[:auto_stop_action] = auto_stop_action if auto_stop_action
          options[:differencing_disk] = differencing_disk if differencing_disk
          options[:enable_virtualization_extensions] = "True" if enable_virtualization_extensions and enable_virtualization_extensions == true

          env[:ui].detail("Creating and registering the VM...")
          server = env[:machine].provider.driver.import(options)

          env[:ui].detail("Setting VM Integration Services")
          vm_integration_services.each do |key, value|
            state = false
            if value === true
              state = "enabled"
            elsif value === false
              state = "disabled"
            end
            env[:ui].output("#{key} is #{state}") if state
          end

          vm_integration_services[:VmId] = server["id"]
          env[:machine].provider.driver.set_vm_integration_services(vm_integration_services)

          env[:ui].detail("Successfully imported a VM with name: #{server['name']}")
          env[:machine].id = server["id"]
          @app.call(env)
        end
      end
    end
  end
end
