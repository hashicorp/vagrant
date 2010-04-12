module Vagrant
  module Provisioners
    # This class implements provisioning via chef-solo.
    class ChefSolo < Chef
      def prepare
        share_cookbook_folders
        share_role_folders
      end

      def provision!
        chown_provisioning_folder
        setup_json
        setup_solo_config
        run_chef_solo
      end

      def share_cookbook_folders
        host_cookbook_paths.each_with_index do |cookbook, i|
          env.config.vm.share_folder("v-csc-#{i}", cookbook_path(i), cookbook)
        end
      end

      def share_role_folders
        host_role_paths.each_with_index do |role, i|
          env.config.vm.share_folder("v-csr-#{i}", role_path(i), role)
        end
      end

      def setup_solo_config
        setup_config("chef_solo_solo", "solo.rb", {
          :provisioning_path => env.config.chef.provisioning_path,
          :cookbooks_path => cookbooks_path,
          :roles_path => roles_path
        })
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

      def host_folder_paths(paths)
        [paths].flatten.collect { |path| File.expand_path(path, env.root_path) }
      end

      def folder_path(folder, i)
        File.join(env.config.chef.provisioning_path, "#{folder}-#{i}")
      end

      def folders_path(folders, folder)
        result = []
        folders.each_with_index do |host_path, i|
          result << folder_path(folder, i)
        end

        # We're lucky that ruby's string and array syntax for strings is the
        # same as JSON, so we can just convert to JSON here and use that
        result = result[0].to_s if result.length == 1
        result.to_json
      end

      def host_cookbook_paths
        host_folder_paths(env.config.chef.cookbooks_path)
      end

      def host_role_paths
        host_folder_paths(env.config.chef.roles_path)
      end

      def cookbook_path(i)
        folder_path("cookbooks", i)
      end

      def role_path(i)
        folder_path("roles", i)
      end

      def cookbooks_path
        folders_path(host_cookbook_paths, "cookbooks")
      end

      def roles_path
        folders_path(host_role_paths, "roles")
      end
    end
  end
end
