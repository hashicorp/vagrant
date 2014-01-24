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

            if !env.has_key?(:box_outdated_refresh)
              env[:box_outdated_refresh] = true
              env[:box_outdated_ignore_errors] = true
            end
          end

          if !machine.box
            # The box doesn't exist. I suppose technically that means
            # that it is "outdated" but we show a specialized error
            # message anyways.
            raise Errors::BoxOutdatedNoBox, name: machine.config.vm.box
          end

          if env[:box_outdated_refresh]
            env[:ui].output(I18n.t(
              "vagrant.box_outdated_checking_with_refresh",
              name: machine.box.name))
            begin
              check_outdated_refresh(env)
            rescue Errors::VagrantError => e
              raise if !env[:box_outdated_ignore_errors]
              env[:ui].detail(I18n.t(
                "vagrant.box_outdated_metadata_error",
                message: e.message))
            end
          else
            @logger.info("Checking if box is outdated locally")
            check_outdated_local(env)
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

        def check_outdated_refresh(env)
          machine = env[:machine]

          if !machine.box.metadata_url
            # This box doesn't have a metadata URL, so we can't
            # possibly check the version information.
            raise Errors::BoxOutdatedNoMetadata, name: machine.box.name
          end

          md = machine.box.load_metadata
          newer = md.version(
            "> #{machine.box.version}", provider: machine.box.provider)
          if !newer
            if env[:box_outdated_success_ui]
              env[:ui].success(I18n.t(
                "vagrant.box_up_to_date_single",
                name: machine.box.name,
                version: machine.box.version))
            end

            env[:box_outdated] = false
            return
          end

          env[:ui].warn(I18n.t(
            "vagrant.box_outdated_single",
            name: machine.box.name,
            current: machine.box.version,
            latest: newer.version))
          env[:box_outdated] = true
        end
      end
    end
  end
end
