module Vagrant
  module Provisioners
    # This class implements provisioning via chef-solo.
    class ChefSolo < Chef
      def prepare
        Vagrant.config.vm.share_folder("vagrant-chef-solo", cookbooks_path, File.expand_path(Vagrant.config.chef.cookbooks_path, Env.root_path))
      end

      def provision!
        chown_provisioning_folder
        setup_json
        setup_solo_config
        run_chef_solo
      end

      def setup_solo_config
        solo_file = <<-solo
file_cache_path "#{Vagrant.config.chef.provisioning_path}"
cookbook_path "#{cookbooks_path}"
solo

        logger.info "Uploading chef-solo configuration script..."
        SSH.upload!(StringIO.new(solo_file), File.join(Vagrant.config.chef.provisioning_path, "solo.rb"))
      end

      def run_chef_solo
        logger.info "Running chef-solo..."
        SSH.execute do |ssh|
          ssh.exec!("cd #{Vagrant.config.chef.provisioning_path} && sudo chef-solo -c solo.rb -j dna.json") do |channel, data, stream|
            # TODO: Very verbose. It would be easier to save the data and only show it during
            # an error, or when verbosity level is set high
            logger.info("#{stream}: #{data}")
          end
        end
      end

      def cookbooks_path
        File.join(Vagrant.config.chef.provisioning_path, "cookbooks")
      end
    end
  end
end