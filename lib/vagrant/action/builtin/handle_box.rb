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

          box_updated = false
          lock.synchronize do
            if machine.box
              @logger.info("Machine already has box. HandleBox will not run.")
              next
            end

            handle_box(env)
            box_updated = true
          end

          if box_updated
            # Reload the environment and set the VM to be the new loaded VM.
            new_machine = machine.vagrantfile.machine(
              machine.name, machine.provider_name,
              machine.env.boxes, machine.data_dir, machine.env)
            env[:machine].box = new_machine.box
            env[:machine].config = new_machine.config
            env[:machine].provider_config = new_machine.provider_config
          end

          @app.call(env)
        end

        def handle_box(env)
          machine = env[:machine]

          # Determine the set of formats that this box can be in
          box_download_ca_cert = machine.config.vm.box_download_ca_cert
          box_download_ca_path = machine.config.vm.box_download_ca_path
          box_download_client_cert = machine.config.vm.box_download_client_cert
          box_download_insecure = machine.config.vm.box_download_insecure
          box_download_checksum_type = machine.config.vm.box_download_checksum_type
          box_download_checksum = machine.config.vm.box_download_checksum
          box_download_location_trusted = machine.config.vm.box_download_location_trusted
          box_formats = machine.provider_options[:box_format] ||
            machine.provider_name

          version_ui = machine.config.vm.box_version
          version_ui ||= ">= 0"

          env[:ui].output(I18n.t(
            "vagrant.box_auto_adding", name: machine.config.vm.box))
          env[:ui].detail("Box Provider: #{Array(box_formats).join(", ")}")
          env[:ui].detail("Box Version: #{version_ui}")

          begin
            env[:action_runner].run(Vagrant::Action.action_box_add, env.merge({
              box_name: machine.config.vm.box,
              box_url: machine.config.vm.box_url || machine.config.vm.box,
              box_server_url: machine.config.vm.box_server_url,
              box_provider: box_formats,
              box_version: machine.config.vm.box_version,
              box_download_client_cert: box_download_client_cert,
              box_download_ca_cert: box_download_ca_cert,
              box_download_ca_path: box_download_ca_path,
              box_download_insecure: box_download_insecure,
              box_checksum_type: box_download_checksum_type,
              box_checksum: box_download_checksum,
              box_download_location_trusted: box_download_location_trusted,
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
