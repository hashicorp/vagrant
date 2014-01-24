require 'optparse'

module VagrantPlugins
  module CommandBox
    module Command
      class Outdated < Vagrant.plugin("2", :command)
        def execute
          OptionParser.new do |o|
            o.banner = "Usage: vagrant box outdated"
          end

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
              md = box.load_metadata
            rescue Vagrant::Errors::DownloaderError => e
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

          # Success, exit status 0
          0
        end
      end
    end
  end
end
