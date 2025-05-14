# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "log4r"

module Vagrant
  module Action
    module Builtin
      class CloudInitWait

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::cloudinitwait")
        end

        def call(env)
          catch(:complete) do
            machine = env[:machine]
            sentinel_path = machine.data_dir.join("action_cloud_init")

            @logger.info("Checking cloud-init sentinel file...")
            if sentinel_path.file?
              contents = sentinel_path.read.chomp
              if machine.id.to_s == contents
                @logger.info("Sentinel found for cloud-init, skipping")
                throw :complete
              end
              @logger.debug("Found stale sentinel file, removing... (#{machine.id} != #{contents})")
              sentinel_path.unlink
            end

            cloud_init_wait_cmd = "cloud-init status --wait"
            if !machine.config.vm.cloud_init_configs.empty?
              if machine.communicate.test("command -v cloud-init")
                env[:ui].output(I18n.t("vagrant.cloud_init_waiting"))
                result = machine.communicate.sudo(cloud_init_wait_cmd, error_check: false)
                if result != 0
                  raise Vagrant::Errors::CloudInitCommandFailed, cmd: cloud_init_wait_cmd, guest_name: machine.name
                end
              else
                raise Vagrant::Errors::CloudInitNotFound, guest_name: machine.name
              end
            end
            # Write sentinel path
            sentinel_path.write(machine.id.to_s)
          end

          @app.call(env)
        end
      end
    end
  end
end
