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
            "EnableAutomaticCheckpoints" => env[:machine].provider_config.enable_automatic_checkpoints,
            "VirtualizationExtensions" => !!env[:machine].provider_config.enable_virtualization_extensions,
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

          if env[:machine].provider_config.enable_enhanced_session_mode
            env[:ui].detail(I18n.t("vagrant.hyperv_enable_enhanced_session"))
            env[:machine].provider.driver.set_enhanced_session_transport_type("HvSocket")
          else
            env[:ui].detail(I18n.t("vagrant.hyperv_disable_enhanced_session"))
            env[:machine].provider.driver.set_enhanced_session_transport_type("VMBus")
          end

          @app.call(env)
        end
      end
    end
  end
end
