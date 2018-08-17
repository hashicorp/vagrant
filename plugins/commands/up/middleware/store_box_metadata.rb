require "json"

module VagrantPlugins
  module CommandUp
    # Stores metadata information about the box used
    # for the current guest. This allows Vagrant to
    # determine the box currently in use when the
    # Vagrantfile is modified with a new box name or
    # version while the guest still exists.
    class StoreBoxMetadata
      def initialize(app, env)
        @app = app
        @logger = Log4r::Logger.new("vagrant::up::storeboxmetadata")
      end

      def call(env)
        if env[:machine].box
          box = env[:machine].box
          box_meta = {
            name: box.name,
            version: box.version,
            provider: box.provider,
            directory: box.directory.sub(Vagrant.user_data_path.to_s + "/", "")
          }
          meta_file = env[:machine].data_dir.join("box_meta")
          @logger.debug("Writing box metadata file to #{meta_file}")
          File.open(meta_file.to_s, "w+") do |file|
            file.write(JSON.dump(box_meta))
          end
        else
          @logger.debug("No box data found for #{env[:machine].name} with provider #{env[:machine].provider_name}")
        end
        @app.call(env)
      end
    end
  end
end
