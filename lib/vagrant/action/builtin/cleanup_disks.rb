# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "json"

module Vagrant
  module Action
    module Builtin
      class CleanupDisks
        # Removes any attached disks no longer defined in a Vagrantfile config
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::disk")
        end

        def call(env)
          machine = env[:machine]
          defined_disks = get_disks(machine, env)

          # Call into providers machine implementation for disk management
          disk_meta_file = read_disk_metadata(machine)

          if !disk_meta_file.empty?
            if machine.provider.capability?(:cleanup_disks)
              machine.provider.capability(:cleanup_disks, defined_disks, disk_meta_file)
            else
              env[:ui].warn(I18n.t("vagrant.actions.disk.provider_unsupported",
                                   provider: machine.provider_name))
            end
          end

          # Continue On
          @app.call(env)
        end

        def read_disk_metadata(machine)
          meta_file = machine.data_dir.join("disk_meta")
          if File.file?(meta_file)
            disk_meta = JSON.parse(meta_file.read)
          else
            @logger.info("No previous disk_meta file defined for guest #{machine.name}")
            disk_meta = {}
          end

          return disk_meta
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
