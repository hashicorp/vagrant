module Vagrant
  module Actions
    module VM
      class Provision < Base
        def execute!
          chown_provisioning_folder
          setup_json
          setup_solo_config
          run_chef_solo
        end

        def chown_provisioning_folder
          logger.info "Setting permissions on provisioning folder..."
          SSH.execute do |ssh|
            ssh.exec!("sudo chown #{Vagrant.config.ssh.username} #{Vagrant.config.chef.provisioning_path}")
          end
        end

        def setup_json
          logger.info "Generating JSON and uploading..."

          # Set up initial configuration
          data = {
            :config => Vagrant.config,
            :directory => Vagrant.config.vm.project_directory,
          }

          # And wrap it under the "vagrant" namespace
          data = { :vagrant => data }

          # Merge with the "extra data" which isn't put under the
          # vagrant namespace by default
          data.merge!(Vagrant.config.chef.json)

          json = data.to_json

          SSH.upload!(StringIO.new(json), File.join(Vagrant.config.chef.provisioning_path, "dna.json"))
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
          logger.info "Running chef recipes..."
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

        def collect_shared_folders
          ["vagrant-provisioning", File.expand_path(Vagrant.config.chef.cookbooks_path, Env.root_path), cookbooks_path]
        end
      end
    end
  end
end
