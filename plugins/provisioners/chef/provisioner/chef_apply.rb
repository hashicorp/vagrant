require "digest/md5"
require "tempfile"

require_relative "base"

module VagrantPlugins
  module Chef
    module Provisioner
      class ChefApply < Base
        def provision
          install_chef
          verify_binary(chef_binary_path("chef-apply"))

          command = "chef-apply"
          command << " \"#{target_recipe_path}\""
          command << " --log_level #{config.log_level}"

          user = @machine.ssh_info[:username]

          # Reset upload path permissions for the current ssh user
          if windows?
            @machine.communicate.sudo("mkdir ""#{config.upload_path}"" -f")
          else
            @machine.communicate.sudo("mkdir -p #{config.upload_path}")
            @machine.communicate.sudo("chown -R #{user} #{config.upload_path}")
          end

          # Upload the recipe
          upload_recipe

          @machine.ui.info(I18n.t("vagrant.provisioners.chef.running_apply",
            script: config.path)
          )

          # Execute it with sudo
          @machine.communicate.sudo(command) do |type, data|
            if [:stderr, :stdout].include?(type)
              # Output the data with the proper color based on the stream.
              color = (type == :stdout) ? :green : :red

              # Chomp the data to avoid the newlines that the Chef outputs
              @machine.env.ui.info(data.chomp, color: color, prefix: false)
            end
          end
        end

        # The destination (on the guest) where the recipe will live
        # @return [String]
        def target_recipe_path
          key = Digest::MD5.hexdigest(config.recipe)
          File.join(config.upload_path, "recipe-#{key}.rb")
        end

        # Write the raw recipe contents to a tempfile and upload that to the
        # machine.
        def upload_recipe
          # Write the raw recipe contents to a tempfile and upload
          Tempfile.open(["vagrant-chef-apply", ".rb"]) do |f|
            f.binmode
            f.write(config.recipe)
            f.fsync
            f.close

            # Upload the tempfile to the guest
            @machine.communicate.upload(f.path, target_recipe_path)
          end
        end
      end
    end
  end
end
