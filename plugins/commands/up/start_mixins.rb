module VagrantPlugins
  module CommandUp
    module StartMixins
      # This adds the standard `start` command line flags to the given
      # OptionParser, storing the result in the `options` dictionary.
      #
      # @param [OptionParser] parser
      # @param [Hash] options
      def build_start_options(parser, options)
        # Setup the defaults
        options[:provision_types] = nil

        # Add the options
        parser.on("--[no-]provision", "Enable or disable provisioning") do |p|
          options[:provision_enabled] = p
          options[:provision_ignore_sentinel] = true
        end

        parser.on("--provision-with x,y,z", Array,
                "Enable only certain provisioners, by type.") do |list|
          options[:provision_types] = list.map { |type| type.to_sym }
          options[:provision_enabled] = true
          options[:provision_ignore_sentinel] = true
        end
      end

      # This validates the provisioner flags and raises an exception
      # if there are invalid ones.
      def validate_provisioner_flags!(options)
        (options[:provision_types] || []).each do |type|
            klass = Vagrant.plugin("2").manager.provisioners[type]
            if !klass
              raise Vagrant::Errors::ProvisionerFlagInvalid,
                name: type.to_s
            end
        end
      end
    end
  end
end
