require 'optparse'

require_relative 'download_mixins'

module VagrantPlugins
  module CommandBox
    module Command
      class Outdated < Vagrant.plugin("2", :command)
        include DownloadMixins

        def execute
          options = {}
          download_options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant box outdated [options]"
            o.separator ""
            o.separator "Checks if there is a new version available for the box"
            o.separator "that are you are using. If you pass in the --global flag,"
            o.separator "all boxes will be checked for updates."
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("--global", "Check all boxes installed") do |g|
              options[:global] = g
            end

            build_download_options(o, download_options)
          end

          argv = parse_options(opts)
          return if !argv

          # If we're checking the boxes globally, then do that.
          if options[:global]
            outdated_global(download_options)
            return 0
          end

          with_target_vms(argv) do |machine|
            @env.action_runner.run(Vagrant::Action.action_box_outdated, {
              box_outdated_force: true,
              box_outdated_refresh: true,
              box_outdated_success_ui: true,
              machine: machine,
            }.merge(download_options))
          end
        end

        def outdated_global(download_options)
          boxes = {}
          @env.boxes.all.reverse.each do |name, version, provider|
            next if boxes[name]
            boxes[name] = @env.boxes.find(name, provider, version)
          end

          boxes.values.each do |box|
            if !box.metadata_url
              @env.ui.output(I18n.t(
                "vagrant.box_outdated_no_metadata",
                name: box.name))
              next
            end

            md = nil
            begin
              md = box.load_metadata(download_options)
            rescue Vagrant::Errors::BoxMetadataDownloadError => e
              @env.ui.error(I18n.t(
                "vagrant.box_outdated_metadata_error",
                name: box.name,
                message: e.extra_data[:message]))
              next
            end

            current = Gem::Version.new(box.version)
            latest  = Gem::Version.new(md.versions.last)
            if latest <= current
              @env.ui.success(I18n.t(
                "vagrant.box_up_to_date",
                name: box.name,
                version: box.version))
            else
              @env.ui.warn(I18n.t(
                "vagrant.box_outdated",
                name: box.name,
                current: box.version,
                latest: latest.to_s,))
            end
          end
        end
      end
    end
  end
end
