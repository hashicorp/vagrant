module Vagrant
  module Provisioners
    # This class is a base class where the common functinality shared between
    # chef-solo and chef-client provisioning are stored. This is **not an actual
    # provisioner**. Instead, {ChefSolo} or {ChefServer} should be used.
    class Chef < Base
      # This is the configuration which is available through `config.chef`
      class ChefConfig < Vagrant::Config::Base
        attr_accessor :cookbooks_path
        attr_accessor :provisioning_path
        attr_accessor :json

        def initialize
          @cookbooks_path = "cookbooks"
          @provisioning_path = "/tmp/vagrant-chef"
          @json = {
            :instance_role => "vagrant",
            :run_list => ["recipe[vagrant_main]"]
          }
        end

        def to_json
          # Overridden so that the 'json' key could be removed, since its just
          # merged into the config anyways
          data = instance_variables_hash
          data.delete(:json)
          data.to_json
        end
      end

      # Tell the Vagrant configure class about our custom configuration
      Config.configures :chef, ChefConfig

      def prepare
        raise Actions::ActionException.new("Vagrant::Provisioners::Chef is not a valid provisioner! Use ChefSolo or ChefServer instead.")
      end

      def chown_provisioning_folder
        logger.info "Setting permissions on chef provisioning folder..."
        SSH.execute do |ssh|
          ssh.exec!("sudo chown #{Vagrant.config.ssh.username} #{Vagrant.config.chef.provisioning_path}")
        end
      end

      def setup_json
        logger.info "Generating chef JSON and uploading..."

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
    end
  end
end