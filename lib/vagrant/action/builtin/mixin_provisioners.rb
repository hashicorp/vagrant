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
            klass  = Vagrant.plugin("2").manager.provisioners[provisioner.type]

            # This can happen in the case the configuration isn't validated.
            next nil if !klass

            result = klass.new(env[:machine], provisioner.config)

            # Store in the type map so that --provision-with works properly
            @_provisioner_types[result] = provisioner.type

            # Set top level provisioner name to provisioner configs name if top level name not set.
            # This is mostly for handling the shell provisioner, if a user has set its name like:
            #
            #   config.vm.provision "shell", name: "my_provisioner"
            #
            # Where `name` is a shell config option, not a top level provisioner class option
            #
            # Note: `name` is set to a symbol, since it is converted to one via #Config::VM.provision
            provisioner_name = provisioner.name
            if !provisioner_name
              if provisioner.config.respond_to?(:name) &&
                  provisioner.config.name
                provisioner_name = provisioner.config.name.to_sym
              end
            else
              provisioner_name = provisioner_name.to_sym
            end

            # Build up the options
            options = {
              name: provisioner_name,
              run:  provisioner.run,
              before:  provisioner.before,
              after:  provisioner.after,
              communicator_required: provisioner.communicator_required,
            }

            # Return the result
            [result, options]
          end

          @_provisioner_instances = sort_provisioner_instances(@_provisioner_instances)
          return @_provisioner_instances.compact
        end

        private

        # Sorts provisioners based on order specified with before/after options
        #
        # @return [Array<Provisioner, Hash>]
        def sort_provisioner_instances(pvs)
          final_provs = []
          root_provs = []
          # extract root provisioners
          root_provs = pvs.find_all { |_, o| o[:before].nil? && o[:after].nil? }

          if root_provs.size == pvs.size
            # no dependencies found
            return pvs
          end

          # ensure placeholder variables are Arrays
          dep_provs = []
          each_provs = []
          all_provs = []

          # extract dependency provisioners
          dep_provs = pvs.find_all { |_, o| o[:before].is_a?(String) || o[:after].is_a?(String) }
          # extract each provisioners
          each_provs = pvs.find_all { |_,o| o[:before] == :each || o[:after] == :each }
          # extract all provisioners
          all_provs = pvs.find_all { |_,o| o[:before] == :all || o[:after] == :all }

          # insert provisioners in order
          final_provs = root_provs
          dep_provs.each do |p,options|
            idx = 0
            if options[:before]
              idx = final_provs.index { |_, o| o[:name].to_s == options[:before] }
              final_provs.insert(idx, [p, options])
            elsif options[:after]
              idx = final_provs.index { |_, o| o[:name].to_s == options[:after] }
              idx += 1
              final_provs.insert(idx, [p, options])
            end
          end

          # Add :each and :all provisioners in reverse to preserve order in Vagrantfile
          tmp_final_provs = []
          final_provs.each_with_index do |(prv,o), i|
            tmp_before = []
            tmp_after = []

            each_provs.reverse_each do |p, options|
              if options[:before]
                tmp_before << [p,options]
              elsif options[:after]
                tmp_after << [p,options]
              end
            end

            tmp_final_provs += tmp_before unless tmp_before.empty?
            tmp_final_provs += [[prv,o]]
            tmp_final_provs += tmp_after unless tmp_after.empty?
          end
          final_provs = tmp_final_provs

          # Add all to final array
          all_provs.reverse_each do |p,options|
            if options[:before]
              final_provs.insert(0, [p,options])
            elsif options[:after]
              final_provs.push([p,options])
            end
          end

          return final_provs
        end

        # This will return a mapping of a provisioner instance to its
        # type.
        def provisioner_type_map(env)
          # Call this in order to initial the map if it hasn't been already
          provisioner_instances(env)

          # Return the type map
          @_provisioner_types
        end

        # @private
        # Reset the cached values for platform. This is not considered a public
        # API and should only be used for testing.
        def self.reset!
          instance_variables.each(&method(:remove_instance_variable))
        end
      end
    end
  end
end
