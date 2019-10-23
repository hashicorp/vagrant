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

          # Check that provider plugin is installed for disk
          # If not, log warning or error to user that disks won't be managed

          # Continue On
          @app.call(env)
        end

        def get_disks(machine, env)
          return @_disks if @_disks

          @_disks = []
          @_disks = machine.config.vm.disks.map do |disk|
            # initialize the disk provider??
          end

          @_disks
        end
      end
    end
  end
end
