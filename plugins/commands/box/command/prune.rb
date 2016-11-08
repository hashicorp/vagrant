require 'optparse'

module VagrantPlugins
  module CommandBox
    module Command
      class Prune < Vagrant.plugin("2", :command)
        def execute
          options = {}
          options[:force] = false
          options[:dry_run] = false

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant box prune [options]"
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("-p PROVIDER", "--provider PROVIDER", String, "The specific provider type for the boxes to destroy.") do |p|
              options[:provider] = p
            end

            o.on("-n", "--dry-run", "Only print the boxes that would be removed.") do |f|
              options[:dry_run] = f
            end

            o.on("--name NAME", String, "The specific box name to check for outdated versions.") do |name|
              options[:name] = name
            end

            o.on("-f", "--force", "Destroy without confirmation even when box is in use.") do |f|
              options[:force] = f
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          boxes = @env.boxes.all.sort
          if boxes.empty?
            return @env.ui.warn(I18n.t("vagrant.commands.box.no_installed_boxes"), prefix: false)
          end

          delete_oldest_boxes(boxes, options[:provider], options[:force], options[:name], options[:dry_run])

          # Success, exit status 0
          0
        end

        private

        def delete_oldest_boxes(boxes, only_provider, skip_confirm, only_name, dry_run)
          # Find the longest box name
          longest_box = boxes.max_by { |x| x[0].length }
          longest_box_length = longest_box[0].length

          # Hash map to keep track of newest versions
          newest_boxes = Hash.new

          # First find the newest version for every installed box
          boxes.each do |name, version, provider|
            next if only_provider and only_provider != provider.to_s
            next if only_name and only_name != name

            # Nested to make sure it works for boxes with different providers
            if newest_boxes.has_key?(name)
              if newest_boxes[name].has_key?(provider)
                saved = Gem::Version.new(newest_boxes[name][provider])
                current = Gem::Version.new(version)
                if current > saved
                  newest_boxes[name][provider] = version
                end
              else
                newest_boxes[name][provider] = version
              end
            else
              newest_boxes[name] = Hash.new
              newest_boxes[name][provider] = version
            end
          end

          @env.ui.info("The following boxes will be kept...");
          newest_boxes.each do |name, providers|
            providers.each do |provider, version|
              @env.ui.info("#{name.ljust(longest_box_length)} (#{provider}, #{version})")

              @env.ui.machine("box-name", name)
              @env.ui.machine("box-provider", provider)
              @env.ui.machine("box-version", version)
            end
          end

          @env.ui.info("", prefix: false)
          @env.ui.info("Checking for older boxes...");

          # Track if we removed anything so the user can be informed
          removed_any_box = false
          boxes.each do |name, version, provider|
            next if !newest_boxes.has_key?(name) or !newest_boxes[name].has_key?(provider)

            current = Gem::Version.new(version)
            saved = Gem::Version.new(newest_boxes[name][provider])
            if current < saved
              removed_any_box = true

              # Use the remove box action
              if dry_run
                @env.ui.info("Would remove #{name} #{provider} #{version}")
              else
                @env.action_runner.run(Vagrant::Action.action_box_remove, {
                    box_name: name,
                    box_provider: provider,
                    box_version: version,
                    force_confirm_box_remove: skip_confirm,
                    box_remove_all_versions: false,
                })
              end
            end
          end

          if !removed_any_box
            @env.ui.info("No old versions of boxes to remove...");
          end
        end
      end
    end
  end
end
