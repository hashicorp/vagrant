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

            # Build up the options
            options = {
              name: provisioner.name,
              run:  provisioner.run,
              before:  provisioner.before,
              after:  provisioner.after,
            }

            # Return the result
            [result, options]
          end

          @_provisioner_instances = sort_provisioner_instances(@_provisioner_instances)
          return @_provisioner_instances.compact
        end

        # Sorts provisioners based on order specified with before/after options
        #
        # TODO: make sure all defined provisioners work here (i.e. even thoughs defined in separate but loaded Vagrantfile)
        #
        # @return [Array<Provisioner, Hash>]
        def sort_provisioner_instances(pvs)
          final_provs = []
          root_provs = []
          dep_provs = []
          each_provs = []
          all_provs = []

          # extract root provisioners
          root_provs = pvs.map { |p,o| [p,o] if o[:before].nil? && o[:after].nil? }.reject(&:nil?)

          if root_provs.size == pvs.size
            # no dependencies found
            return pvs
          end

          # extract dependency provisioners
          dep_provs = pvs.map { |p,o| [p,o] if (!o[:before].nil? && !o[:before].is_a?(Symbol)) || (!o[:after].nil? && !o[:after].is_a?(Symbol)) }.reject(&:nil?)
          # extract each provisioners
          each_provs = pvs.map { |p,o| [p,o] if o[:before] == :each || o[:after] == :each }.reject(&:nil?)
          # extract all provisioners
          all_provs = pvs.map { |p,o| [p,o] if o[:before] == :all || o[:after] == :all }.reject(&:nil?)

          # TODO: Log here, that provisioner order is being changed

          # insert provisioners in order
          final_provs = root_provs
          dep_provs.each do |p,options|
            if options[:before]
              idx = final_provs.each_with_index.map { |(p,o), i| i if o[:name].to_s == options[:before] }.reject(&:nil?).first
              idx -= 1 unless idx == 0
              final_provs.insert(idx, [p, options])
            elsif options[:after]
              idx = final_provs.each_with_index.map { |(p,o), i| i if o[:name].to_s == options[:after] }.reject(&:nil?).first
              idx += 1
              final_provs.insert(idx, [p, options])
            end
          end

          # add each to final array
          tmp_final_provs = final_provs.dup
          extra_index = 0
          each_provs.reverse_each do |p,options|
            final_provs.each_with_index.map do |(prv,o), i|
              if options[:before]
                idx = i-1 unless idx == 0
                idx += extra_index
                extra_index += 1
                tmp_final_provs.insert(idx, [p,options])
              elsif options[:after]
                idx = i+1
                idx += extra_index
                extra_index += 1
                tmp_final_provs.insert(idx, [p,options])
              end
            end
          end
          final_provs = tmp_final_provs

          # add all to final array
          tmp_final_provs = final_provs.dup
          all_provs.reverse_each do |p,options|
            if options[:before]
              tmp_final_provs.insert(0, [p,options])
            elsif options[:after]
              tmp_final_provs.push([p,options])
            end
          end
          final_provs = tmp_final_provs

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
      end
    end
  end
end
