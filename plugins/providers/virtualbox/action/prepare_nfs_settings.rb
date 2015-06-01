require "vagrant/action/builtin/mixin_synced_folders"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class PrepareNFSSettings
        include Vagrant::Action::Builtin::MixinSyncedFolders
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::action::vm::nfs")
        end

        def call(env)
          @machine = env[:machine]

          @app.call(env)

          opts = {
            cached: !!env[:synced_folders_cached],
            config: env[:synced_folders_config],
            disable_usable_check: !!env[:test],
          }
          folders = synced_folders(env[:machine], **opts)

          if folders.key?(:nfs)
            @logger.info("Using NFS, preparing NFS settings by reading host IP and machine IP")
            add_ips_to_env!(env)
          end
        end

        # Extracts the proper host and guest IPs for NFS mounts and stores them
        # in the environment for the SyncedFolder action to use them in
        # mounting.
        #
        # The ! indicates that this method modifies its argument.
        def add_ips_to_env!(env)
          adapter, host_ip = find_host_only_adapter
          machine_ip       = read_static_machine_ips || read_dynamic_machine_ip(adapter)

          raise Vagrant::Errors::NFSNoHostonlyNetwork if !host_ip || !machine_ip

          env[:nfs_host_ip]    = host_ip
          env[:nfs_machine_ip] = machine_ip
        end

        # Finds first host only network adapter and returns its adapter number
        # and IP address
        #
        # @return [Integer, String] adapter number, ip address of found host-only adapter
        def find_host_only_adapter
          @machine.provider.driver.read_network_interfaces.each do |adapter, opts|
            if opts[:type] == :hostonly
              @machine.provider.driver.read_host_only_interfaces.each do |interface|
                if interface[:name] == opts[:hostonly]
                  return adapter, interface[:ip]
                end
              end
            end
          end

          nil
        end

        # Returns the IP address(es) of the guest by looking for static IPs
        # given to host only adapters in the Vagrantfile
        #
        # @return [Array]<String> Configured static IPs
        def read_static_machine_ips
          ips = []
          @machine.config.vm.networks.each do |type, options|
            if type == :private_network && options[:type] != :dhcp && options[:ip].is_a?(String)
              ips << options[:ip]
            end
          end

          if ips.empty?
            return nil
          end

          ips
        end

        # Returns the IP address of the guest by looking at vbox guest property
        # for the appropriate guest adapter.
        #
        # For DHCP interfaces, the guest property will not be present until the
        # guest completes
        #
        # @param [Integer] adapter number to read IP for
        # @return [String] ip address of adapter
        def read_dynamic_machine_ip(adapter)
          return nil unless adapter

          # vbox guest properties are 0-indexed, while showvminfo network
          # interfaces are 1-indexed. go figure.
          guestproperty_adapter = adapter - 1

          # we need to wait for the guest's IP to show up as a guest property.
          # retry thresholds are relatively high since we might need to wait
          # for DHCP, but even static IPs can take a second or two to appear.
          retryable(retry_options.merge(on: Vagrant::Errors::VirtualBoxGuestPropertyNotFound)) do
            @machine.provider.driver.read_guest_ip(guestproperty_adapter)
          end
        rescue Vagrant::Errors::VirtualBoxGuestPropertyNotFound
          # this error is more specific with a better error message directing
          # the user towards the fact that it's probably a reportable bug
          raise Vagrant::Errors::NFSNoGuestIP
        end

        # Separating these out so we can stub out the sleep in tests
        def retry_options
          {tries: 15, sleep: 1}
        end
      end
    end
  end
end
