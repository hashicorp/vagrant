# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

Vagrant.require 'optparse'

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

          boxes = @env.boxes.all
          if boxes.empty?
            @env.ui.warn(I18n.t("vagrant.commands.box.no_installed_boxes"), prefix: false)
            return 0
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

          # Group boxes by name and version and start iterating
          boxes.group_by { |b| [b[0], b[1]] }.each do |box_info, box_data|
            name, version = box_info
            # Now group by provider so we can collect common architectures
            box_data.group_by { |b| b[2] }.each do |provider, data|
              architectures = data.map { |d| d.last }.compact.sort.uniq
              meta_info = [provider, version]
              if !architectures.empty?
                meta_info << "(#{architectures.join(", ")})"
              end
              @env.ui.info("#{name.ljust(longest_box_length)} (#{meta_info.join(", ")})")
              data.each do |arch_info|
                @env.ui.machine("box-name", name)
                @env.ui.machine("box-provider", provider)
                @env.ui.machine("box-version", version)
                @env.ui.machine("box-architecture", arch_info.last || "n/a")
                info_file = @env.boxes.find(name, provider, version, arch_info.last).
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
  end
end
