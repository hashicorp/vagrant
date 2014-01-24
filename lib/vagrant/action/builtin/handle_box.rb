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
            if !machine.config.vm.box_url
              handle_metadata_box(env)
            else
              handle_direct_box(env)
            end
          end

          @app.call(env)
        end

        def handle_direct_box(env)
        end

        def handle_metadata_box(env)
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
              box_url: machine.config.vm.box,
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

=begin
        def call(env)
          if !env[:machine].config.vm.box || !env[:machine].config.vm.box_url
            @logger.info("Skipping HandleBoxUrl because box or box_url not set.")
            @app.call(env)
            return
          end

          if env[:machine].box
            @logger.info("Skipping HandleBoxUrl because box is already available")
            @app.call(env)
            return
          end

          # Get a "big lock" to make sure that our more fine grained
          # lock access is thread safe.
          lock = nil
          @@big_lock.synchronize do
            lock = @@handle_box_url_locks[env[:machine].config.vm.box]
          end

          box_name = env[:machine].config.vm.box
          box_url  = env[:machine].config.vm.box_url
          box_download_ca_cert = env[:machine].config.vm.box_download_ca_cert
          box_download_checksum = env[:machine].config.vm.box_download_checksum
          box_download_checksum_type = env[:machine].config.vm.box_download_checksum_type
          box_download_client_cert = env[:machine].config.vm.box_download_client_cert
          box_download_insecure = env[:machine].config.vm.box_download_insecure

          # Expand the CA cert file relative to the Vagrantfile path, if
          # there is one.
          if box_download_ca_cert
            box_download_ca_cert = File.expand_path(
              box_download_ca_cert, env[:machine].env.root_path)
          end

          lock.synchronize do
            # Check that we don't already have the box, which can happen
            # if we're slow to acquire the lock because of another thread
            box_formats = env[:machine].provider_options[:box_format] ||
              env[:machine].provider_name
            if env[:box_collection].find(box_name, box_formats)
              break
            end

            # Add the box then reload the box collection so that it becomes
            # aware of it.
            env[:ui].info I18n.t(
              "vagrant.actions.vm.check_box.not_found",
              :name => box_name,
              :provider => env[:machine].provider_name)

            begin
              env[:action_runner].run(Vagrant::Action.action_box_add, {
                :box_checksum => box_download_checksum,
                :box_checksum_type => box_download_checksum_type,
                :box_client_cert => box_download_client_cert,
                :box_download_ca_cert => box_download_ca_cert,
                :box_download_insecure => box_download_insecure,
                :box_name     => box_name,
                :box_provider => box_formats,
                :box_url      => box_url,
              })
            rescue Errors::BoxAlreadyExists
              # Just ignore this, since it means the next part will succeed!
              # This can happen in a multi-threaded environment.
            end
          end

          # Reload the environment and set the VM to be the new loaded VM.
          env[:machine] = env[:machine].env.machine(
            env[:machine].name, env[:machine].provider_name, true)

          @app.call(env)
        end
=end
      end
    end
  end
end
