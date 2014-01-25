require "log4r"

module Vagrant
  module Action
    module Builtin
      # This middleware checks if there are outdated boxes. By default,
      # it only checks locally, but if `box_outdated_refresh` is set, it
      # will refresh the metadata associated with a box.
      class BoxCheckOutdated
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new(
            "vagrant::action::builtin::box_check_outdated")
        end

        def call(env)
          machine = env[:machine]

          if !env[:box_outdated_force]
            if !machine.config.vm.box_check_update
              return @app.call(env)
            end
          end

          if !machine.box
            # The box doesn't exist. I suppose technically that means
            # that it is "outdated" but we show a specialized error
            # message anyways.
            raise Errors::BoxOutdatedNoBox, name: machine.config.vm.box
          end
          box = machine.box
          constraints = machine.config.vm.box_version

          env[:ui].output(I18n.t(
            "vagrant.box_outdated_checking_with_refresh",
            name: box.name))
          update = nil
          begin
            update = box.has_update?(constraints)
          rescue Errors::VagrantError => e
            raise if !env[:box_outdated_ignore_errors]
            env[:ui].detail(I18n.t(
              "vagrant.box_outdated_metadata_error_single",
              message: e.message))
          end
          env[:box_outdated] = update != nil
          if update
            env[:ui].warn(I18n.t(
              "vagrant.box_outdated_single",
              name: update[0].name,
              current: box.version,
              latest: update[1].version))
          end

          @app.call(env)
        end

        def check_outdated_local(env)
          machine = env[:machine]
          box = env[:box_collection].find(
            machine.box.name, machine.box.provider,
            "> #{machine.box.version}")
          if box
            env[:ui].warn(I18n.t(
              "vagrant.box_outdated_local",
              name: box.name,
              old: machine.box.version,
              new: box.version))
            env[:box_outdated] = true
            return
          end

          env[:box_outdated] = false
        end
      end
    end
  end
end
