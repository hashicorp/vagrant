# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "json"

module Vagrant
  module Action
    module Builtin
      class Disk
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::disk")
        end

        def call(env)
          machine = env[:machine]
          defined_disks = get_disks(machine, env)

          # Call into providers machine implementation for disk management
          configured_disks = {}
          if !defined_disks.empty?
            if machine.provider.capability?(:configure_disks)
             configured_disks = machine.provider.capability(:configure_disks, defined_disks)
            else
              env[:ui].warn(I18n.t("vagrant.actions.disk.provider_unsupported",
                                 provider: machine.provider_name))
            end
          end

          write_disk_metadata(machine, configured_disks) unless configured_disks.empty?

          # Continue On
          @app.call(env)
        end

        def write_disk_metadata(machine, current_disks)
          meta_file = machine.data_dir.join("disk_meta")
          @logger.debug("Writing disk metadata file to #{meta_file}")
          File.open(meta_file.to_s, "w+") do |file|
            file.write(JSON.dump(current_disks))
          end
        end

        def get_disks(machine, env)
          return @_disks if @_disks

          @_disks = []
          @_disks = machine.config.vm.disks

          @_disks
        end
      end
    end
  end
end
