module Hobo
  class Provisioning
    include Hobo::Util

    def initialize(vm)
      @vm = vm

      # Share the cookbook folder. We'll use the provisioning path exclusively for
      # chef stuff.
      @vm.share_folder("hobo-provisioning", File.expand_path(Hobo.config.chef.cookbooks_path, Env.root_path), cookbooks_path)
    end

    def run
      chown_provisioning_folder
      setup_json
      setup_solo_config
    end

    def chown_provisioning_folder
      logger.info "Setting permissions on provisioning folder..."
      SSH.execute do |ssh|
        ssh.exec!("sudo chown #{Hobo.config.ssh.username} #{Hobo.config.chef.provisioning_path}")
      end
    end

    def setup_json
      logger.info "Generating JSON and uploading..."
      SSH.upload!(StringIO.new(Hobo.config.chef.json.to_json), File.join(Hobo.config.chef.provisioning_path, "dna.json"))
    end

    def setup_solo_config
      solo_file = <<-solo
file_cache_path "#{Hobo.config.chef.provisioning_path}"
cookbook_path "#{cookbooks_path}"
solo

      logger.info "Uploading chef-solo configuration script..."
      SSH.upload!(StringIO.new(solo_file), File.join(Hobo.config.chef.provisioning_path, "solo.rb"))
    end

    def cookbooks_path
      File.join(Hobo.config.chef.provisioning_path, "cookbooks")
    end
  end
end