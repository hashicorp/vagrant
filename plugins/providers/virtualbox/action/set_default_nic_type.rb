require "log4r"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      # This sets the default NIC type used for network adapters created
      # on the guest. Also includes a check of NIC types in use and VirtualBox
      # version to determine if E1000 NIC types are vulnerable.
      #
      # NOTE: Vulnerability was fixed here: https://www.virtualbox.org/changeset/75330/vbox
      class SetDefaultNICType
        # Defines versions of VirtualBox with susceptible implementation
        # of the E1000 devices.
        E1000_SUSCEPTIBLE = Gem::Requirement.new("< 5.2.22").freeze

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::plugins::virtualbox::set_default_nic_type")
          @app    = app
        end

        def call(env)
          default_nic_type = env[:machine].provider_config.default_nic_type

          e1000_in_use = [
            # simple check on default_nic_type
            ->{ default_nic_type.nil? || default_nic_type.to_s.start_with?("8254") },
            # check provider defined adapters
            ->{ env[:machine].provider_config.network_adapters.values.detect{ |_, opts|
                opts[:nic_type].to_s.start_with?("8254") } },
            # finish with inspecting configured networks
            ->{ env[:machine].config.vm.networks.detect{ |_, opts|
                opts.fetch(:virtualbox__nic_type, opts[:nic_type]).to_s.start_with?("8254") } }
          ]

          # Check if VirtualBox E1000 implementation is vulnerable
          if E1000_SUSCEPTIBLE.satisfied_by?(Gem::Version.new(env[:machine].provider.driver.version))
            @logger.info("Detected VirtualBox version with susceptible E1000 implementation (`#{E1000_SUSCEPTIBLE}`)")
            if e1000_in_use.any?(&:call)
              env[:ui].warn I18n.t("vagrant.actions.vm.set_default_nic_type.e1000_warning")
            end
          end

          if default_nic_type
            @logger.info("Default NIC type for VirtualBox interfaces `#{default_nic_type}`")
            # Update network adapters defined in provider configuration
            env[:machine].provider_config.network_adapters.each do |slot, args|
              _, opts = args
              if opts && !opts.key?(:nic_type)
                @logger.info("Setting default NIC type (`#{default_nic_type}`) adapter `#{slot}` - `#{args}`")
                opts[:nic_type] = default_nic_type
              end
            end

            # Update generally defined networks
            env[:machine].config.vm.networks.each do |type, options|
              next if !type.to_s.end_with?("_network")
              if !options.key?(:nic_type) && !options.key?(:virtualbox__nic_type)
                @logger.info("Setting default NIC type (`#{default_nic_type}`) for `#{type}` - `#{options}`")
                options[:virtualbox__nic_type] = default_nic_type
              end
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
