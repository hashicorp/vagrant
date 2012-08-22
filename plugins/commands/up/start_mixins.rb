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
        options["provision.enabled"] = true
        options["provision.types"] = nil

        # Add the options
        parser.on("--[no-]provision", "Enable or disable provisioning") do |p|
          options["provision.enabled"] = p
        end

        parser.on("--provision-with x,y,z", Array,
                "Enable only certain provisioners, by type.") do |list|
          options["provision.types"] = list
        end
      end
    end
  end
end
