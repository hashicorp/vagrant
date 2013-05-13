require "rubygems"
require "rubygems/user_interaction"
require "rubygems/uninstaller"
require "set"

require "log4r"

module VagrantPlugins
  module CommandPlugin
    module Action
      # This class prunes any unnecessary gems from the Vagrant-managed
      # gem folder. This keeps the gem folder to the absolute minimum set
      # of required gems and doesn't let it blow up out of control.
      #
      # A high-level description of how this works:
      #
      #   1. Get the list of installed plugins. Vagrant maintains this
      #     list on its own.
      #   2. Get the list of installed RubyGems.
      #   3. Find the latest version of each RubyGem that matches an installed
      #      plugin. These are our root RubyGems that must be installed.
      #   4. Go through each root and mark all dependencies recursively as
      #      necessary.
      #   5. Set subtraction between all gems and necessary gems yields a
      #      list of gems that aren't needed. Uninstall them.
      #
      class PruneGems
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::plugins::plugincommand::prune")
        end

        def call(env)
          @logger.info("Pruning gems...")

          # Get the list of installed plugins according to the state file
          installed = Set.new(env[:plugin_state_file].installed_plugins)

          # Get the actual specifications of installed gems
          all_specs = env[:gem_helper].with_environment do
            result = []
            Gem::Specification.find_all { |s| result << s }
            result
          end

          # The list of specs to prune initially starts out as all of them
          all_specs = Set.new(all_specs)

          # Go through each spec and find the latest version of the installed
          # gems, since we want to keep those.
          installed_specs = {}

          @logger.debug("Collecting installed plugin gems...")
          all_specs.each do |spec|
            # If this isn't a spec that we claim is installed, skip it
            next if !installed.include?(spec.name)

            # If it is already in the specs, then we need to make sure we
            # have the latest version.
            if installed_specs.has_key?(spec.name)
              if installed_specs[spec.name].version > spec.version
                next
              end
            end

            @logger.debug(" -- #{spec.name} (#{spec.version})")
            installed_specs[spec.name] = spec
          end

          # Recursive dependency checker to keep all dependencies and remove
          # all non-crucial gems from the prune list.
          good_specs = Set.new
          to_check   = installed_specs.values

          while true
            # If we're out of gems to check then we break out
            break if to_check.empty?

            # Get a random (first) element to check
            spec = to_check.shift

            # If we already checked this, then do the next one
            next if good_specs.include?(spec)

            # Find all the dependencies and add the latest compliant gem
            # to the `to_check` list.
            if spec.dependencies.length > 0
              @logger.debug("Finding dependencies for '#{spec.name}' to mark as good...")
              spec.dependencies.each do |dep|
                # Ignore non-runtime dependencies
                next if dep.type != :runtime
                @logger.debug("Searching for: '#{dep.name}'")

                latest_matching = nil

                all_specs.each do |prune_spec|
                  if dep =~ prune_spec
                    # If we have a matching one already and this one isn't newer
                    # then we ditch it.
                    next if latest_matching &&
                      prune_spec.version <= latest_matching.version

                    latest_matching = prune_spec
                  end
                end

                if latest_matching.nil?
                  @logger.error("Missing dependency for '#{spec.name}': #{dep.name}")
                  next
                end

                @logger.debug("Latest matching dep: '#{latest_matching.name}' (#{latest_matching.version})")
                to_check << latest_matching
              end
            end

            # Add ito the list of checked things so we don't accidentally
            # re-check it
            good_specs.add(spec)
          end

          # Figure out the gems we need to prune
          prune_specs = all_specs - good_specs
          @logger.debug("Gems to prune: #{prune_specs.inspect}")
          @logger.info("Pruning #{prune_specs.length} gems.")

          if prune_specs.length > 0
            env[:gem_helper].with_environment do
              prune_specs.each do |prune_spec|
                uninstaller = Gem::Uninstaller.new(prune_spec.name, {
                  :all         => true,
                  :executables => true,
                  :force       => true,
                  :ignore      => true,
                  :version     => prune_spec.version.version
                })

                @logger.info("Uninstalling: #{prune_spec.name} (#{prune_spec.version})")
                uninstaller.uninstall
              end
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
