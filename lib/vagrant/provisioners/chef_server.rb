module Vagrant
  module Provisioners
    # This class implements provisioning via chef-client, allowing provisioning
    # with a chef server.
    class ChefServer < Chef
      def prepare
        if Vagrant.config.chef.validation_key_path.nil?
          raise Actions::ActionException.new(:chef_server_validation_key_required)
        elsif !File.file?(Vagrant.config.chef.validation_key_path)
          raise Actions::ActionException.new(:chef_server_validation_key_doesnt_exist)
        end

        if Vagrant.config.chef.chef_server_url.nil?
          raise Actions::ActionException.new(:chef_server_url_required)
        end
      end

      def provision!
        chown_provisioning_folder
        create_client_key_folder
        upload_validation_key
        setup_json
        setup_config
        run_chef_client
      end

      def create_client_key_folder
        logger.info "Creating folder to hold client key..."
        path = Pathname.new(Vagrant.config.chef.client_key_path)

        SSH.execute do |ssh|
          ssh.exec!("sudo mkdir -p #{path.dirname}")
        end
      end

      def upload_validation_key
        logger.info "Uploading chef client validation key..."
        SSH.upload!(validation_key_path, guest_validation_key_path)
      end

      def setup_config
        solo_file = <<-solo
log_level          :info
log_location       STDOUT
ssl_verify_mode    :verify_none
chef_server_url    "#{Vagrant.config.chef.chef_server_url}"

validation_client_name "#{Vagrant.config.chef.validation_client_name}"
validation_key         "#{guest_validation_key_path}"
client_key             "#{Vagrant.config.chef.client_key_path}"

file_store_path    "/srv/chef/file_store"
file_cache_path    "/srv/chef/cache"

pid_file           "/var/run/chef/chef-client.pid"

Mixlib::Log::Formatter.show_time = true
solo

        logger.info "Uploading chef-client configuration script..."
        SSH.upload!(StringIO.new(solo_file), File.join(Vagrant.config.chef.provisioning_path, "client.rb"))
      end

      def run_chef_client
        logger.info "Running chef-client..."
        SSH.execute do |ssh|
          ssh.exec!("cd #{Vagrant.config.chef.provisioning_path} && sudo chef-client -c client.rb -j dna.json") do |channel, data, stream|
            # TODO: Very verbose. It would be easier to save the data and only show it during
            # an error, or when verbosity level is set high
            logger.info("#{stream}: #{data}")
          end
        end
      end

      def validation_key_path
        File.expand_path(Vagrant.config.chef.validation_key_path, Env.root_path)
      end

      def guest_validation_key_path
        File.join(Vagrant.config.chef.provisioning_path, "validation.pem")
      end
    end
  end
end