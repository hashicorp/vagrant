require 'optparse'

module VagrantPlugins
  module CommandBox
    module Command
      class List < Vagrant.plugin("2", :command)
        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant box list [options]"
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("-i", "--box-info", "Displays additional information about the boxes") do |i|
              options[:info] = i
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          boxes = @env.boxes.all.sort
          if boxes.empty?
            return @env.ui.warn(I18n.t("vagrant.commands.box.no_installed_boxes"), prefix: false)
          end

          list_boxes(boxes, options[:info])

          # Success, exit status 0
          0
        end

        private

        def list_boxes(boxes, extra_info)
          # Find the longest box name
          longest_box = boxes.max_by { |x| x[0].length }
          longest_box_length = longest_box[0].length

          # Go through each box and output the information about it. We
          # ignore the "v1" param for now since I'm not yet sure if its
          # important for the user to know what boxes need to be upgraded
          # and which don't, since we plan on doing that transparently.
          boxes.each do |name, version, provider|
            @env.ui.info("#{name.ljust(longest_box_length)} (#{provider}, #{version})")

            @env.ui.machine("box-name", name)
            @env.ui.machine("box-provider", provider)
            @env.ui.machine("box-version", version)

            info_file = @env.boxes.find(name, provider, version).
              directory.join("info.json")
            if info_file.file?
              info = JSON.parse(info_file.read)
              info.each do |k, v|
                @env.ui.machine("box-info", k, v)

                if extra_info
                  @env.ui.info("  - #{k}: #{v}", prefix: false)
                end
              end
            end
          end
        end
      end
    end
  end
end
