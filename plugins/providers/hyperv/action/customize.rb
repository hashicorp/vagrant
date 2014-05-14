require "log4r"

module VagrantPlugins
  module HyperV
    module Action
      class Customize

        def initialize(app, env, event)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::hyperv::connection")
          @event  = event
        end

        def call(env)
          customizations = []
          @env = env
          env[:machine].provider_config.customizations.each do |event, command|
            if event == @event
              customizations << command
            end
          end

          if !customizations.empty?
            env[:ui].info I18n.t("vagrant.actions.vm.customize.running", event: @event)
            customizations.each do |query|
              command = query[0]
              params = query[1]
              if self.respond_to?("custom_action_#{command}")
                self.send("custom_action_#{command}", params)
              end
            end
          end

          validate_virtual_switch
          @app.call(env)
        end

        def custom_action_virtual_switch(params)
          options = { vm_id: @env[:machine].id,
                      type: (params[:type] || "").downcase  || "external",
                      name: params[:name],
                      adapter: (params[:bridge] || "").downcase
                    }

          if options[:type] == "private"
            @env[:ui].detail I18n.t("vagrant_hyperv.private_switch_not_allowed")
            return
          end

          response = @env[:machine].provider.driver.switch_exist({ name: options[:name],
                                              type: options[:type]})

          if options[:type] == "internal"
            @env[:ui].detail(" ")
            @env[:ui].detail I18n.t("vagrant_hyperv.internal_switch_warn")
            @env[:ui].detail(" ")
            if response["message"] == "switch exist"
              add_swith_to_vm(options)
              return
            else
              raise Errors::NoSwitchFound,
                type: options[:type], name: options[:name]
            end
          end

          if options[:type] == "external"
            if response["message"] == "switch exist"
              if (response["switch_name"].casecmp(options[:name]) == 0)
                add_swith_to_vm(options)
                return
              else
                raise Errors::ExternalSwitchExist, name: response["switch_name"]
              end
            end

            adapters = @env[:machine].provider.driver.list_net_adapters
            available_adapters = adapters.map { |a| a["Name"].downcase }

            unless available_adapters.include? (options[:adapter])
              @env[:ui].detail I18n.t("vagrant_hyperv.net_adapter_warn")
              selected_adapter = choose_option_from(adapters, "adapter")
              options[:adapter] = selected_adapter["Name"]
            end

            @env[:ui].info I18n.t("vagrant_win_hyperv.creating_switch",
              { type: options[:type], name: options[:name] })
            response = @env[:machine].provider.driver.create_network_switch(options)
            case response["message"]
              when "Network down"
                raise Errors::NetworkDown
              when "Success"
                add_swith_to_vm(options)
            end
          end
        end

        def add_swith_to_vm(options)
          current_vm_switch = @env[:machine].provider.driver.find_vm_switch_name
          if current_vm_switch["network_adapter"].nil?
            raise VagrantPlugins::VagrantHyperV::Errors::NoNetworkAdapter
          end
          @env[:machine].provider.driver.add_swith_to_vm(options)
        end

        def validate_virtual_switch
          @env[:ui].info "Validating Virtual Switch"
          current_vm_switch = @env[:machine].provider.driver.find_vm_switch_name

          if current_vm_switch["switch_name"].nil?
            switches = @env[:machine].provider.driver.execute("get_switches.ps1", {})
            raise Errors::NoSwitches if switches.empty?

            switch = choose_option_from(switches, "switch")
            switch_type = nil
            case switch["SwitchType"]
            when 1
              switch_type = "Internal"
            when 2
              switch_type = "External"
            end

            options = { vm_id: @env[:machine].id,
                        type: switch_type.downcase,
                        name: switch["Name"]
                      }
            @env[:ui].info I18n.t("vagrant_hyperv.add_switch_to_vm",
              { type: options[:type], name: options[:name] })

            add_swith_to_vm(options)
          end
        end

        private
        def choose_option_from(options, key)
          @env[:ui].detail(I18n.t("vagrant_hyperv.choose_#{key}") + "\n ")
          options.each_index do |i|
            option = options[i]
            @env[:ui].detail("#{i+1}) #{option["Name"]}")
          end
          @env[:ui].detail(" ")

          selected = nil
          while !selected
            selected = @env[:ui].ask("What #{key} would you like to use? ")
            next if !selected
            selected = selected.to_i - 1
            selected = nil if selected < 0 || selected >= options.length
          end
          options[selected]
        end
      end
    end
  end
end
