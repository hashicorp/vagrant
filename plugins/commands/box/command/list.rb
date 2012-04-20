require 'optparse'

module VagrantPlugins
  module CommandBox
    module Command
      class List < Vagrant::Command::Base
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

          # Success, exit status 0
          0
        end
      end
    end
  end
end
