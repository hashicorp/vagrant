require "thread"

require "log4r"

module Vagrant
  module Action
    module Builtin
      # This built-in middleware handles the `box` setting by verifying
      # the box is already installed, dowloading the box if it isn't,
      # updating the box if it is requested, etc.
      class HandleBox
        @@big_lock = Mutex.new
        @@small_locks = Hash.new { |h,k| h[k] = Mutex.new }

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::handle_box")
        end

        def call(env)
          machine = env[:machine]

          if !machine.config.vm.box
            @logger.info("Skipping HandleBox because no box is set")
            return @app.call(env)
          end

          # Acquire a lock for this box to handle multi-threaded
          # environments.
          lock = nil
          @@big_lock.synchronize do
            lock = @@small_locks[machine.config.vm.box]
          end

          lock.synchronize do
            handle_box(env)
          end

          # Reload the environment and set the VM to be the new loaded VM.
          env[:machine] = env[:machine].env.machine(
            env[:machine].name, env[:machine].provider_name, true)

          @app.call(env)
        end

        def handle_box(env)
          machine = env[:machine]

          if machine.box
            @logger.info("Machine already has box. HandleBox will not run.")
            return
          end

          # Determine the set of formats that this box can be in
          box_download_ca_cert = env[:machine].config.vm.box_download_ca_cert
          box_download_client_cert = env[:machine].config.vm.box_download_client_cert
          box_download_insecure = env[:machine].config.vm.box_download_insecure
          box_formats = env[:machine].provider_options[:box_format] ||
            env[:machine].provider_name

          env[:ui].output(I18n.t(
            "vagrant.box_auto_adding", name: machine.config.vm.box))
          env[:ui].detail("Box Provider: #{Array(box_formats).join(", ")}")
          env[:ui].detail("Box Version: #{machine.config.vm.box_version}")

          begin
            env[:action_runner].run(Vagrant::Action.action_box_add, env.merge({
              box_name: machine.config.vm.box,
              box_url: machine.config.vm.box_url || machine.config.vm.box,
              box_provider: box_formats,
              box_version: machine.config.vm.box_version,
              box_client_cert: box_download_client_cert,
              box_download_ca_cert: box_download_ca_cert,
              box_download_insecure: box_download_insecure,
            }))
          rescue Errors::BoxAlreadyExists
            # Just ignore this, since it means the next part will succeed!
            # This can happen in a multi-threaded environment.
          end
        end
      end
    end
  end
end
