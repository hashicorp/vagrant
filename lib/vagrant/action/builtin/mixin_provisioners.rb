module Vagrant
  module Action
    module Builtin
      module MixinProvisioners
        # This returns all the instances of the configured provisioners.
        # This is safe to call multiple times since it will cache the results.
        #
        # @return [Array<Provisioner, Hash>]
        def provisioner_instances(env)
          return @_provisioner_instances if @_provisioner_instances

          # Make the mapping that'll keep track of provisioner => type
          @_provisioner_types = {}

          # Get all the configured provisioners
          @_provisioner_instances = env[:machine].config.vm.provisioners.map do |provisioner|
            # Instantiate the provisioner
            klass  = Vagrant.plugin('2').manager.provisioners[provisioner.name]
            result = klass.new(env[:machine], provisioner.config)

            # Store in the type map so that --provision-with works properly
            @_provisioner_types[result] = provisioner.name

            # Build up the options
            options = {
              run: provisioner.run,
            }

            # Return the result
            [result, options]
          end

          @_provisioner_instances
        end

        # This will return a mapping of a provisioner instance to its
        # type.
        def provisioner_type_map(env)
          # Call this in order to initial the map if it hasn't been already
          provisioner_instances(env)

          # Return the type map
          @_provisioner_types
        end
      end
    end
  end
end
