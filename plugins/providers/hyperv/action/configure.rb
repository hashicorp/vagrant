require "fileutils"

require "log4r"

module VagrantPlugins
  module HyperV
    module Action
      class Configure
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::hyperv::configure")
        end

        def call(env)
          switches = env[:machine].provider.driver.execute(:get_switches)
          if switches.empty?
            raise Errors::NoSwitches
          end

          switch = nil
          env[:machine].config.vm.networks.each do |type, opts|
            next if type != :public_network && type != :private_network

            if opts[:bridge]
              @logger.debug("Looking for switch with name or ID: #{opts[:bridge]}")
              switch = switches.find{ |s|
                s["Name"].downcase == opts[:bridge].to_s.downcase ||
                  s["Id"].downcase == opts[:bridge].to_s.downcase
              }
              if switch
                @logger.debug("Found switch - Name: #{switch["Name"]} ID: #{switch["Id"]}")
                switch = switch["Id"]
                break
              end
            end
          end
          
          
          # TODO: Should be controllers as we want to be able to have several lines.
          #if !env[:machine].provider_config.controllers.empty?
          #  puts "hej: controller not empty"
          #  #env[:ui].detail("Controllers set")
          #  #controller.each do [key, value]
          #  #  puts "key: #{id} value: #{value}"
          #  #  if [type].include?(key)
          #  #    puts "key matches type"
          #  #  end
          #  #end
          #  
          #  env[:machine].provider_config.controller.each do |key, value|
          #    env[:ui].output("#{key} is #{value}")
          #  end
          #
          #  #env[:machine].provider.driver.set_vm_integration_services(
          #  #  env[:machine].provider_config.vm_integration_services)
          #end

          disks_to_create = []
          env[:machine].provider_config.controllers.each { |controller|
            #puts "configure.rb: controller: #{controller}"
            
            next_is_size = false
            disk_name = ''
            controller[:disks].each { |i|
              #puts "configure.rb: i: #{i} disk_name: #{disk_name}"
              if !next_is_size
                if File.file?(i)
                  create_disk = false 
                  filename_for_disk = i
                  next_is_size = false
                
                  @logger.error("Attaching disks is not implemented yet")
                else
                  create_disk = true
                  disk_name = i
                  next_is_size = true
                  #puts "configure.rb: disk_name set to: #{disk_name}"
                end
              else
                #puts "configure.rb: Adding disk to create. name: #{disk_name}"
                disks_to_create << { name: "\"#{disk_name}\"", size: i}
              end
            }
          }
          #puts "configure.rb: disks_to_create:#{disks_to_create}"
          disks_to_create_json = disks_to_create.to_json
          puts "configure.rb: json: #{disks_to_create_json}"

          # If we already configured previously don't prompt for switch
          sentinel = env[:machine].data_dir.join("action_configure")

          if !switch && !sentinel.file?
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
              switch = switches[switch]["Id"]
            else
              switch = switches.first["Id"]
              @logger.debug("Only single switch available so using that.")
            end
          end

          options = {
            "VMID" => env[:machine].id,
            "SwitchID" => switch,
            "Memory" => env[:machine].provider_config.memory,
            "MaxMemory" => env[:machine].provider_config.maxmemory,
            "Processors" => env[:machine].provider_config.cpus,
            "AutoStartAction" => env[:machine].provider_config.auto_start_action,
            "AutoStopAction" => env[:machine].provider_config.auto_stop_action,
            "EnableCheckpoints" => env[:machine].provider_config.enable_checkpoints,
            "VirtualizationExtensions" => !!env[:machine].provider_config.enable_virtualization_extensions,
            "DisksToCreate" => disks_to_create_json
          }
          options.delete_if{|_,v| v.nil? }

          env[:ui].detail("Configuring the VM...")
          env[:machine].provider.driver.execute(:configure_vm, options)

          # Create the sentinel
          if !sentinel.file?
            sentinel.open("w") do |f|
              f.write(Time.now.to_i.to_s)
            end
          end

          if !env[:machine].provider_config.vm_integration_services.empty?
            env[:ui].detail("Setting VM Integration Services")

            env[:machine].provider_config.vm_integration_services.each do |key, value|
              state = value ? "enabled" : "disabled"
              env[:ui].output("#{key} is #{state}")
            end

            env[:machine].provider.driver.set_vm_integration_services(
              env[:machine].provider_config.vm_integration_services)
          end

          @app.call(env)
        end
      end
    end
  end
end
