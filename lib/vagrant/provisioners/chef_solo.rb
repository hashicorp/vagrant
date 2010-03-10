module Vagrant
  module Provisioners
    # This class implements provisioning via chef-solo.
    class ChefSolo < Base
      # This is the configuration which is available through `config.chef_solo`
      class CustomConfig < Vagrant::Config::Base
        attr_accessor :cookbooks_path
        attr_accessor :provisioning_path
        attr_accessor :json

        def to_json
          # Overridden so that the 'json' key could be removed, since its just
          # merged into the config anyways
          data = instance_variables_hash
          data.delete(:json)
          data.to_json
        end
      end

      # Tell the Vagrant configure class about our custom configuration
      Config.configures :chef_solo, CustomConfig

      def prepare
        Vagrant.config.vm.share_folder("vagrant-chef-solo", cookbooks_path, File.expand_path(Vagrant.config.chef_solo.cookbooks_path, Env.root_path))
      end

      def provision!
        chown_provisioning_folder
        setup_json
        setup_solo_config
        run_chef_solo
      end

      def chown_provisioning_folder
        logger.info "Setting permissions on chef solo provisioning folder..."
        SSH.execute do |ssh|
          ssh.exec!("sudo chown #{Vagrant.config.ssh.username} #{Vagrant.config.chef_solo.provisioning_path}")
        end
      end

      def setup_json
        logger.info "Generating chef solo JSON and uploading..."

        # Set up initial configuration
        data = {
          :config => Vagrant.config,
          :directory => Vagrant.config.vm.project_directory,
        }

        # And wrap it under the "vagrant" namespace
        data = { :vagrant => data }

        # Merge with the "extra data" which isn't put under the
        # vagrant namespace by default
        data.merge!(Vagrant.config.chef_solo.json)

        json = data.to_json

        SSH.upload!(StringIO.new(json), File.join(Vagrant.config.chef_solo.provisioning_path, "dna.json"))
      end

      def setup_solo_config
        solo_file = <<-solo
file_cache_path "#{Vagrant.config.chef_solo.provisioning_path}"
cookbook_path "#{cookbooks_path}"
solo

        logger.info "Uploading chef-solo configuration script..."
        SSH.upload!(StringIO.new(solo_file), File.join(Vagrant.config.chef_solo.provisioning_path, "solo.rb"))
      end

      def run_chef_solo
        logger.info "Running chef-solo..."
        SSH.execute do |ssh|
          ssh.exec!("cd #{Vagrant.config.chef_solo.provisioning_path} && sudo chef-solo -c solo.rb -j dna.json") do |channel, data, stream|
            # TODO: Very verbose. It would be easier to save the data and only show it during
            # an error, or when verbosity level is set high
            logger.info("#{stream}: #{data}")
          end
        end
      end

      def cookbooks_path
        File.join(Vagrant.config.chef_solo.provisioning_path, "cookbooks")
      end
    end
  end
end