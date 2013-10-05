require 'optparse'

require_relative "base"

module VagrantPlugins
  module CommandBox
    module Command
      class List < Base
        def execute
          options = {}

          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant box list"
            opts.separator ""

            opts.on("-i", "--box-info", "Displays additional information about the boxes.") do |i|
              options[:info] = i
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          boxes = @env.boxes.all.sort
          if boxes.empty?
            return @env.ui.warn(I18n.t("vagrant.commands.box.no_installed_boxes"), :prefix => false)
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

          # Find the longest provider name
          longest_provider = boxes.max_by { |x| x[1].length }
          longest_provider_length = longest_provider[1].length

          # Go through each box and output the information about it. We
          # ignore the "v1" param for now since I'm not yet sure if its
          # important for the user to know what boxes need to be upgraded
          # and which don't, since we plan on doing that transparently.
          boxes.each do |name, provider, _v1|
            extra = ''
            if extra_info
              extra << "\n  `- URL:  #{box_state_file.box_url(name, provider)}"
              extra << "\n  `- Date: #{box_state_file.downloaded_at(name, provider)}"
            end

            name     = name.ljust(longest_box_length)
            provider = "(#{provider})".ljust(longest_provider_length + 2) # 2 -> parenthesis
            box_info = "#{name} #{provider}#{extra}"

            @env.ui.info(box_info, :prefix => false)
          end
        end
      end
    end
  end
end
