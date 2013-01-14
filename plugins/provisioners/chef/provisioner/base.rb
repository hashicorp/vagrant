require 'tempfile'

require "vagrant/util/counter"
require "vagrant/util/template_renderer"

module VagrantPlugins
  module Chef
    module Provisioner
      # This class is a base class where the common functionality shared between
      # chef-solo and chef-client provisioning are stored. This is **not an actual
      # provisioner**. Instead, {ChefSolo} or {ChefServer} should be used.
      class Base < Vagrant.plugin("2", :provisioner)
        class ChefError < Vagrant::Errors::VagrantError
          error_namespace("vagrant.provisioners.chef")
        end

        include Vagrant::Util::Counter

        def initialize(machine, config)
          super

          config.provisioning_path ||= "/tmp/vagrant-chef-#{get_and_update_counter(:provisioning_path)}"
        end

        def verify_binary(binary)
          # Checks for the existence of chef binary and error if it
          # doesn't exist.
          @machine.communicate.sudo(
            "which #{binary}",
            :error_class => ChefError,
            :error_key => :chef_not_detected,
            :binary => binary)
        end

        # Returns the path to the Chef binary, taking into account the
        # `binary_path` configuration option.
        def chef_binary_path(binary)
          return binary if !@config.binary_path
          return File.join(@config.binary_path, binary)
        end

        def chown_provisioning_folder
          @machine.communicate.tap do |comm|
            comm.sudo("mkdir -p #{@config.provisioning_path}")
            comm.sudo("chown #{@machine.config.ssh.username} #{@config.provisioning_path}")
          end
        end

        def setup_config(template, filename, template_vars)
          config_file = Vagrant::Util::TemplateRenderer.render(template, {
            :log_level        => @config.log_level.to_sym,
            :http_proxy       => @config.http_proxy,
            :http_proxy_user  => @config.http_proxy_user,
            :http_proxy_pass  => @config.http_proxy_pass,
            :https_proxy      => @config.https_proxy,
            :https_proxy_user => @config.https_proxy_user,
            :https_proxy_pass => @config.https_proxy_pass,
            :no_proxy         => @config.no_proxy
          }.merge(template_vars))

          # Create a temporary file to store the data so we
          # can upload it
          temp = Tempfile.new("vagrant")
          temp.write(config_file)
          temp.close

          remote_file = File.join(config.provisioning_path, filename)
          @machine.communicate.tap do |comm|
            comm.sudo("rm #{remote_file}", :error_check => false)
            comm.upload(temp.path, remote_file)
          end
        end

        def setup_json
          @machine.env.ui.info I18n.t("vagrant.provisioners.chef.json")

          # Get the JSON that we're going to expose to Chef
          json = JSON.pretty_generate(@config.merged_json)

          # Create a temporary file to store the data so we
          # can upload it
          temp = Tempfile.new("vagrant")
          temp.write(json)
          temp.close

          @machine.communicate.upload(temp.path, File.join(@config.provisioning_path, "dna.json"))
        end
      end
    end
  end
end
