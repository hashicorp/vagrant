module Vagrant
  # This class provides a way to load and access the contents
  # of a Vagrantfile.
  #
  # This class doesn't actually load Vagrantfiles, parse them,
  # merge them, etc. That is the job of {Config::Loader}. This
  # class, on the other hand, has higher-level operations on
  # a loaded Vagrantfile such as looking up the defined machines,
  # loading the configuration of a specific machine/provider combo,
  # etc.
  class Vagrantfile
    # Initializes by loading a Vagrantfile.
    #
    # @param [Config::Loader] loader Configuration loader that should
    #   already be configured with the proper Vagrantflie locations.
    #   This usually comes from {Vagrant::Environment}
    # @param [Array<Symbol>] keys The Vagrantfiles to load and the
    #   order to load them in (keys within the loader).
    def initialize(loader, keys)
      @keys   = keys
      @loader = loader
      @config, _ = loader.load(keys)
    end

    # Returns the configuration for a single machine.
    #
    # When loading a box Vagrantfile, it will be prepended to the
    # key order specified when initializing this class. Sub-machine
    # and provider-specific overrides are appended at the end. The
    # actual order is:
    #
    # - box
    # - keys specified for #initialize
    # - sub-machine
    # - provider
    #
    # @param [Symbol] name Name of the machine.
    # @param [Symbol] provider The provider the machine should
    #   be backed by (required for provider overrides).
    # @param [BoxCollection] boxes BoxCollection to look up the
    #   box Vagrantfile.
    def machine_config(name, provider, boxes)
      keys = @keys.dup

      sub_machine = @config.vm.defined_vms[name]
      if !sub_machine
        raise Errors::MachineNotFound,
          :name => name, :provider => provider
      end

      provider_plugin  = Vagrant.plugin("2").manager.providers[provider]
      if !provider_plugin
        raise Errors::ProviderNotFound,
          :machine => name, :provider => provider
      end

      box_formats = provider_plugin[1][:box_format] || provider

      # Add the sub-machine configuration to the loader and keys
      vm_config_key = "#{object_id}_machine_#{name}"
      @loader.set(vm_config_key, sub_machine.config_procs)
      keys << vm_config_key

      # Load once so that we can get the proper box value
      config, config_warnings, config_errors = @loader.load(keys)

      # Track the original box so we know if we changed
      original_box = config.vm.box

      # The proc below loads the box and provider overrides. This is
      # in a proc because it may have to recurse if the provider override
      # changes the box.
      load_box_proc = lambda do
        local_keys = keys.dup

        # Load the box Vagrantfile, if there is one
        if config.vm.box
          box = boxes.find(config.vm.box, box_formats)
          if box
            box_vagrantfile = find_vagrantfile(box.directory)
            if box_vagrantfile
              box_config_key =
                "#{boxes.object_id}_#{box.name}_#{box.provider}".to_sym
              @loader.set(box_config_key, box_vagrantfile)
              local_keys.unshift(box_config_key)
              config, config_warnings, config_errors = @loader.load(local_keys)
            end
          end
        end

        # Load provider overrides
        provider_overrides = config.vm.get_provider_overrides(provider)
        if !provider_overrides.empty?
          config_key =
            "#{object_id}_vm_#{name}_#{config.vm.box}_#{provider}".to_sym
          @loader.set(config_key, provider_overrides)
          local_keys << config_key
          config, config_warnings, config_errors = @loader.load(local_keys)
        end

        # If the box changed, then we need to reload
        if original_box != config.vm.box
          # TODO: infinite loop protection?

          original_box = config.vm.box
          load_box_proc.call
        end
      end

      # Load the box and provider overrides
      load_box_proc.call

      return config, config_warnings, config_errors
    end

    # Returns a list of the machines that are defined within this
    # Vagrantfile.
    #
    # @return [Array<Symbol>]
    def machine_names
      @config.vm.defined_vm_keys.dup
    end

    # Returns the name of the machine that is designated as the
    # "primary."
    #
    # In the case of a single-machine environment, this is just the
    # single machine name. In the case of a multi-machine environment,
    # then this is the machine that is marked as primary, or nil if
    # no primary machine was specified.
    #
    # @return [Symbol]
    def primary_machine_name
      # If it is a single machine environment, then return the name
      return machine_names.first if machine_names.length == 1

      # If it is a multi-machine environment, then return the primary
      @config.vm.defined_vms.each do |name, subvm|
        return name if subvm.options[:primary]
      end

      # If no primary was specified, nil it is
      nil
    end

    protected

    def find_vagrantfile(search_path)
      ["Vagrantfile", "vagrantfile"].each do |vagrantfile|
        current_path = search_path.join(vagrantfile)
        return current_path if current_path.file?
      end

      nil
    end
  end
end
