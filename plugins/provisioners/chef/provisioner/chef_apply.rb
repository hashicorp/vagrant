require "tempfile"

module VagrantPlugins
  module Chef
    module Provisioner
      class ChefApply < Vagrant.plugin("2", :provisioner)
        def provision
          command = "chef-apply"
          command << " --log-level #{config.log_level}"
          command << " #{config.upload_path}"

          user = @machine.ssh_info[:username]

          # Reset upload path permissions for the current ssh user
          @machine.communicate.sudo("mkdir -p #{config.upload_path}")
          @machine.communicate.sudo("chown -R #{user} #{config.upload_path}")

          # Upload the recipe
          upload_recipe

          @machine.ui.info(I18n.t("vagrant.provisioners.chef.running_chef_apply",
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

        # Write the raw recipe contents to a tempfile and upload that to the
        # machine.
        def upload_recipe
          # Write the raw recipe contents to a tempfile
          file = Tempfile.new(["vagrant-chef-apply", ".rb"])
          file.write(config.recipe)
          file.rewind

          # Upload the tempfile to the guest
          destination = File.join(config.upload_path, "recipe.rb")
          @machine.communicate.upload(file.path, destination)
        ensure
          # Delete our template
          file.close
          file.unlink
        end
      end
    end
  end
end
