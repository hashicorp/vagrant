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
              @logger.debug(
                "Not checking for update: no force and no update config")
              return @app.call(env)
            end
          end

          if !machine.box
            # We don't have a box. Just ignore, we can't check for
            # outdated...
            @logger.warn("Not checking for update, no box")
            return @app.call(env)
          end

          box = machine.box
          if box.version == "0" && !box.metadata_url
            return @app.call(env)
          end

          constraints = machine.config.vm.box_version
          # Have download options specified in the environment override
          # options specified for the machine.
          download_options = {
            automatic_check: !env[:box_outdated_force],
            ca_cert: env[:ca_cert] || machine.config.vm.box_download_ca_cert,
            ca_path: env[:ca_path] || machine.config.vm.box_download_ca_path,
            client_cert: env[:client_cert] ||
                           machine.config.vm.box_download_client_cert,
            insecure: !env[:insecure].nil? ?
                        env[:insecure] : machine.config.vm.box_download_insecure
          }

          env[:ui].output(I18n.t(
            "vagrant.box_outdated_checking_with_refresh",
            name: box.name,
            version: box.version))
          update = nil
          begin
            update = box.has_update?(constraints, download_options: download_options)
          rescue Errors::BoxMetadataDownloadError => e
            env[:ui].warn(I18n.t(
              "vagrant.box_outdated_metadata_download_error",
              message: e.extra_data[:message]))
          rescue Errors::BoxMetadataMalformed  => e
            @logger.warn(e.to_s)
            env[:ui].warn(I18n.t("vagrant.box_malformed_continue_on_update"))
          rescue Errors::VagrantError => e
            raise if !env[:box_outdated_ignore_errors]
            env[:ui].detail(I18n.t(
              "vagrant.box_outdated_metadata_error_single",
              message: e.message))
          end
          env[:box_outdated] = update != nil
          local_update = check_outdated_local(env)
          if update && (local_update.nil? || (local_update.version < update[1].version))
            env[:ui].warn(I18n.t(
              "vagrant.box_outdated_single",
              name: update[0].name,
              provider: box.provider,
              current: box.version,
              latest: update[1].version))
          elsif local_update
            env[:ui].warn(I18n.t(
              "vagrant.box_outdated_local",
              name: local_update.name,
              old: box.version,
              new: local_update.version))
            env[:box_outdated] = true
          else
            env[:box_outdated] = false
          end

          @app.call(env)
        end

        def check_outdated_local(env)
          machine = env[:machine]

          # Make sure we respect the constraints set within the Vagrantfile
          version = machine.config.vm.box_version
          version += ", " if version
          version ||= ""
          version += "> #{machine.box.version}"

          env[:box_collection].find(
            machine.box.name, machine.box.provider, version)
        end
      end
    end
  end
end
