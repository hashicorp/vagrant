require 'optparse'

module VagrantPlugins
  module CommandBox
    module Command
      class List < Vagrant.plugin("2", :command)
        def execute
          options = {}

          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant box list"
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          boxes = @env.boxes.all.sort
          if boxes.empty?
            return @env.ui.warn(I18n.t("vagrant.commands.box.no_installed_boxes"), :prefix => false)
          end

          # Find the longest box name
          longest_box = boxes.max_by { |x| x[0].length }
          longest_box_length = longest_box[0].length

          # Go through each box and output the information about it. We
          # ignore the "v1" param for now since I'm not yet sure if its
          # important for the user to know what boxes need to be upgraded
          # and which don't, since we plan on doing that transparently.
          boxes.each do |name, provider, _v1|
            @env.ui.info("#{name.ljust(longest_box_length)} (#{provider})", :prefix => false)
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
