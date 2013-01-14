require "log4r"

module Vagrant
  module Action
    module Builtin
      # This class will run the configured provisioners against the
      # machine.
      #
      # This action should be placed BEFORE the machine is booted so it
      # can do some setup, and then run again (on the return path) against
      # a running machine.
      class Provision
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::provision")
        end

        def call(env)
          # Get all the configured provisioners
          provisioners = env[:machine].config.vm.provisioners.map do |provisioner|
            klass = Vagrant.plugin("2").manager.provisioners[provisioner.name]
            klass.new(env[:machine], provisioner.config)
          end

          # Ask the provisioners to modify the configuration if needed
          provisioners.each do |p|
            p.configure(env[:machine].config)
          end

          # Continue, we need the VM to be booted.
          @app.call(env)

          # Actually provision
          provisioners.each do |p|
            env[:ui].info(I18n.t("vagrant.actions.vm.provision.beginning",
                                 :provisioner => p.class))

            p.provision
          end
        end
      end
    end
  end
end
