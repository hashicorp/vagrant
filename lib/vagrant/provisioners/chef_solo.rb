module Vagrant
  module Provisioners
    # This class implements provisioning via chef-solo.
    class ChefSolo < Chef
      register :chef_solo

      extend Util::Counter
      include Util::Counter

      class Config < Chef::Config
        attr_accessor :cookbooks_path
        attr_accessor :roles_path
        attr_accessor :data_bags_path
        attr_accessor :recipe_url
        attr_accessor :nfs

        def initialize
          super

          @cookbooks_path = ["cookbooks", [:vm, "cookbooks"]]
          @roles_path = nil
          @data_bags_path = nil
          @nfs = false
        end

        def validate(errors)
          super

          errors.add(I18n.t("vagrant.config.chef.cookbooks_path_empty")) if !cookbooks_path || [cookbooks_path].flatten.empty?
          errors.add(I18n.t("vagrant.config.chef.run_list_empty")) if !run_list || run_list.empty?
        end
      end

      attr_reader :cookbook_folders
      attr_reader :role_folders
      attr_reader :data_bags_folders

      def prepare
        @cookbook_folders = expanded_folders(config.cookbooks_path)
        @role_folders = expanded_folders(config.roles_path)
        @data_bags_folders = expanded_folders(config.data_bags_path)

        share_folders("csc", @cookbook_folders)
        share_folders("csr", @role_folders)
        share_folders("csdb", @data_bags_folders)
      end

      def provision!
        verify_binary(chef_binary_path("chef-solo"))
        chown_provisioning_folder
        setup_json
        setup_solo_config
        run_chef_solo
      end

      # Converts paths to a list of properly expanded paths with types.
      def expanded_folders(paths)
        return [] if paths.nil?

        # Convert the path to an array if it is a string or just a single
        # path element which contains the folder location (:host or :vm)
        paths = [paths] if paths.is_a?(String) || paths.first.is_a?(Symbol)

        paths.map do |path|
          path = [:host, path] if !path.is_a?(Array)
          type, path = path

          # Create the local/remote path based on whether this is a host
          # or VM path.
          local_path = nil
          local_path = File.expand_path(path, env.root_path) if type == :host
          remote_path = nil
          if type == :host
            # Path exists on the host, setup the remote path
            remote_path = "#{config.provisioning_path}/chef-solo-#{get_and_update_counter(:cookbooks_path)}"
          else
            # Path already exists on the virtual machine. Expand it
            # relative to where we're provisioning.
            remote_path = File.expand_path(path, config.provisioning_path)
          end

          # Return the result
          [type, local_path, remote_path]
        end
      end

      # Shares the given folders with the given prefix. The folders should
      # be of the structure resulting from the `expanded_folders` function.
      def share_folders(prefix, folders)
        folders.each do |type, local_path, remote_path|
          if type == :host
            env.config.vm.share_folder("v-#{prefix}-#{self.class.get_and_update_counter(:shared_folder)}",
                                       remote_path, local_path, :nfs => config.nfs)
          end
        end
      end

      def setup_solo_config
        cookbooks_path = guest_paths(@cookbook_folders)
        roles_path = guest_paths(@role_folders).first
        data_bags_path = guest_paths(@data_bags_folders).first

        setup_config("chef_solo_solo", "solo.rb", {
          :node_name => config.node_name,
          :provisioning_path => config.provisioning_path,
          :cookbooks_path => cookbooks_path,
          :recipe_url => config.recipe_url,
          :roles_path => roles_path,
          :data_bags_path => data_bags_path,
        })
      end

      def run_chef_solo
        command_env = config.binary_env ? "#{config.binary_env} " : ""
        command = "/bin/bash -c 'sudo #{command_env}#{chef_binary_path("/usr/bin/chef-solo")} -c #{config.provisioning_path}/solo.rb -j #{config.provisioning_path}/dna.json'"
        env.ui.info I18n.t("vagrant.provisioners.chef.running_solo")
        vm.ssh.execute { |ssh| ssh.vagrant_type(ssh.vagrant_remote_cmd(command)) }
      end

      # Extracts only the remote paths from a list of folders
      def guest_paths(folders)
        folders.map { |parts| parts[2] }
      end
    end
  end
end
