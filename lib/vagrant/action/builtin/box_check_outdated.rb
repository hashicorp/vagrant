require 'log4r'

module Vagrant
  module Action
    module Builtin
      # This middleware checks if there are outdated boxes. By default,
      # it only checks locally, but if `box_outdated_refresh` is set, it
      # will refresh the metadata associated with a box.
      class BoxCheckOutdated
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new(
            'vagrant::action::builtin::box_check_outdated')
        end

        def call(env)
          machine = env[:machine]

          unless env[:box_outdated_force]
            unless machine.config.vm.box_check_update
              @logger.debug(
                'Not checking for update: no force and no update config')
              return @app.call(env)
            end
          end

          unless machine.box
            # We don't have a box. Just ignore, we can't check for
            # outdated...
            @logger.warn('Not checking for update, no box')
            return @app.call(env)
          end

          box = machine.box
          if box.version == '0' && !box.metadata_url
            return @app.call(env)
          end

          constraints = machine.config.vm.box_version

          env[:ui].output(I18n.t(
            'vagrant.box_outdated_checking_with_refresh',
            name: box.name))
          update = nil
          begin
            update = box.has_update?(constraints)
          rescue Errors::BoxMetadataDownloadError => e
            env[:ui].warn(I18n.t(
              'vagrant.box_outdated_metadata_download_error',
              message: e.extra_data[:message]))
          rescue Errors::VagrantError => e
            raise unless env[:box_outdated_ignore_errors]
            env[:ui].detail(I18n.t(
              'vagrant.box_outdated_metadata_error_single',
              message: e.message))
          end
          env[:box_outdated] = !update.nil?
          if update
            env[:ui].warn(I18n.t(
              'vagrant.box_outdated_single',
              name: update[0].name,
              current: box.version,
              latest: update[1].version))
          else
            check_outdated_local(env)
          end

          @app.call(env)
        end

        def check_outdated_local(env)
          machine = env[:machine]

          # Make sure we respect the constraints set within the Vagrantfile
          version = machine.config.vm.box_version
          version += ', ' if version
          version ||= ''
          version += "> #{machine.box.version}"

          box = env[:box_collection].find(
            machine.box.name, machine.box.provider, version)
          if box
            env[:ui].warn(I18n.t(
              'vagrant.box_outdated_local',
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
