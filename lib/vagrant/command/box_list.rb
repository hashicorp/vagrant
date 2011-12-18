require 'optparse'

module Vagrant
  module Command
    class BoxList < Base
      def execute
        options = {}

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant box list"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        boxes = @env.boxes.sort
        if boxes.empty?
          return @env.ui.warn(I18n.t("vagrant.commands.box.no_installed_boxes"), :prefix => false)
        end
        boxes.each { |b| @env.ui.info(b.name, :prefix => false) }
      end
    end
  end
end
