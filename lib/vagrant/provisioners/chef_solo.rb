module Vagrant
  module Provisioners
    # This class implements provisioning via chef-solo.
    class ChefSolo < Chef
      def prepare
        share_cookbook_folders
      end

      def provision!
        chown_provisioning_folder
        setup_json
        setup_solo_config
        run_chef_solo
      end

      def share_cookbook_folders
        host_cookbook_paths.each_with_index do |cookbook, i|
          env.config.vm.share_folder("vagrant-chef-solo-#{i}", cookbook_path(i), cookbook)
        end
      end

      def setup_solo_config
        solo_file = <<-solo
file_cache_path "#{env.config.chef.provisioning_path}"
cookbook_path #{cookbooks_path}
solo

        logger.info "Uploading chef-solo configuration script..."
        env.ssh.upload!(StringIO.new(solo_file), File.join(env.config.chef.provisioning_path, "solo.rb"))
      end

      def run_chef_solo
        logger.info "Running chef-solo..."
        env.ssh.execute do |ssh|
          ssh.exec!("cd #{env.config.chef.provisioning_path} && sudo chef-solo -c solo.rb -j dna.json") do |channel, data, stream|
            # TODO: Very verbose. It would be easier to save the data and only show it during
            # an error, or when verbosity level is set high
            logger.info("#{stream}: #{data}")
          end
        end
      end

      def host_cookbook_paths
        cookbooks = env.config.chef.cookbooks_path
        cookbooks = [cookbooks] unless cookbooks.is_a?(Array)
        cookbooks.collect! { |cookbook| File.expand_path(cookbook, env.root_path) }
        return cookbooks
      end

      def cookbook_path(i)
        File.join(env.config.chef.provisioning_path, "cookbooks-#{i}")
      end

      def cookbooks_path
        result = []
        host_cookbook_paths.each_with_index do |host_path, i|
          result << cookbook_path(i)
        end

        # We're lucky that ruby's string and array syntax for strings is the
        # same as JSON, so we can just convert to JSON here and use that
        result = result.to_s if result.length == 1
        result.to_json
      end
    end
  end
end