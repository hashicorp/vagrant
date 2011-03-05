module Vagrant
  module Provisioners
    # This class implements provisioning via chef-solo.
    class ChefSolo < Chef
      register :chef_solo

      class Config < Chef::Config
        attr_accessor :cookbooks_path
        attr_accessor :roles_path
        attr_accessor :recipe_url

        def initialize
          super

          @cookbooks_path = ["cookbooks", [:vm, "cookbooks"]]
          @roles_path = []
        end

        def validate(errors)
          super

          errors.add(I18n.t("vagrant.config.chef.cookbooks_path_empty")) if !cookbooks_path || [cookbooks_path].flatten.empty?
          errors.add(I18n.t("vagrant.config.chef.run_list_empty")) if !json[:run_list] || run_list.empty?
        end
      end

      def prepare
        share_cookbook_folders
        share_role_folders
      end

      def provision!
        verify_binary("chef-solo")
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
          :node_name => config.node_name,
          :provisioning_path => config.provisioning_path,
          :cookbooks_path => cookbooks_path,
          :recipe_url => config.recipe_url,
          :roles_path => roles_path,
        })
      end

      def run_chef_solo
        commands = ["cd #{config.provisioning_path}", "chef-solo -c solo.rb -j dna.json"]

        env.ui.info I18n.t("vagrant.provisioners.chef.running_solo")
        vm.ssh.execute do |ssh|
          ssh.sudo!(commands) do |channel, type, data|
            if type == :exit_status
              ssh.check_exit_status(data, commands)
            else
              env.ui.info("#{data}: #{type}")
            end
          end
        end
      end

      def host_folder_paths(paths)
        # Convert single cookbook paths such as "cookbooks" or [:vm, "cookbooks"]
        # into a proper array representation.
        paths = [paths] if paths.is_a?(String) || paths.first.is_a?(Symbol)

        paths.inject([]) do |acc, path|
          path = [:host, path] if !path.is_a?(Array)
          type, path = path

          acc << File.expand_path(path, env.root_path) if type == :host
          acc
        end
      end

      def folder_path(*args)
        File.join(config.provisioning_path, args.join("-"))
      end

      def folders_path(folders, folder)
        # Convert single cookbook paths such as "cookbooks" or [:vm, "cookbooks"]
        # into a proper array representation.
        folders = [folders] if folders.is_a?(String) || folders.first.is_a?(Symbol)

        # Convert each path to the proper absolute path depending on if the path
        # is a host path or a VM path
        result = []
        folders.each_with_index do |path, i|
          path = [:host, path] if !path.is_a?(Array)
          type, path = path

          result << folder_path(folder, i) if type == :host
          result << folder_path(path) if type == :vm
        end

        # We're lucky that ruby's string and array syntax for strings is the
        # same as JSON, so we can just convert to JSON here and use that
        result = result[0].to_s if result.length == 1
        result
      end

      def host_cookbook_paths
        host_folder_paths(config.cookbooks_path)
      end

      def host_role_paths
        host_folder_paths(config.roles_path)
      end

      def cookbook_path(i)
        folder_path("cookbooks", i)
      end

      def role_path(i)
        folder_path("roles", i)
      end

      def cookbooks_path
        folders_path(config.cookbooks_path, "cookbooks").to_json
      end

      def roles_path
        folders_path(config.roles_path, "roles").to_json
      end
    end
  end
end
