require 'tempfile'

require "vagrant/util/template_renderer"

module VagrantPlugins
  module Chef
    module Provisioner
      # This class is a base class where the common functionality shared between
      # chef-solo and chef-client provisioning are stored. This is **not an actual
      # provisioner**. Instead, {ChefSolo} or {ChefServer} should be used.
      class Base < Vagrant.plugin("1", :provisioner)
        include Vagrant::Util::Counter

        def initialize(env, config)
          super

          config.provisioning_path ||= "/tmp/vagrant-chef-#{get_and_update_counter(:provisioning_path)}"
        end

        def verify_binary(binary)
          # Checks for the existence of chef binary and error if it
          # doesn't exist.
          env[:machine].communicate.sudo("which #{binary}",
                                         :error_class => ChefError,
                                         :error_key => :chef_not_detected,
                                         :binary => binary)
        end

        # Returns the path to the Chef binary, taking into account the
        # `binary_path` configuration option.
        def chef_binary_path(binary)
          return binary if !config.binary_path
          return File.join(config.binary_path, binary)
        end

        def chown_provisioning_folder
          env[:machine].communicate.tap do |comm|
            comm.sudo("mkdir -p #{config.provisioning_path}")
            comm.sudo("chown #{env[:machine].config.ssh.username} #{config.provisioning_path}")
          end
        end

        def setup_config(template, filename, template_vars)
          config_file = Vagrant::Util::TemplateRenderer.render(template, {
            :log_level => config.log_level.to_sym,
            :http_proxy => config.http_proxy,
            :http_proxy_user => config.http_proxy_user,
            :http_proxy_pass => config.http_proxy_pass,
            :https_proxy => config.https_proxy,
            :https_proxy_user => config.https_proxy_user,
            :https_proxy_pass => config.https_proxy_pass,
            :no_proxy => config.no_proxy
          }.merge(template_vars))

          # Create a temporary file to store the data so we
          # can upload it
          temp = Tempfile.new("vagrant")
          temp.write(config_file)
          temp.close

          remote_file = File.join(config.provisioning_path, filename)
          env[:machine].communicate.tap do |comm|
            comm.sudo("rm #{remote_file}", :error_check => false)
            comm.upload(temp.path, remote_file)
          end
        end

        def setup_json
          env[:ui].info I18n.t("vagrant.provisioners.chef.json")

          # Get the JSON that we're going to expose to Chef
          json = JSON.pretty_generate(config.merged_json)

          # Create a temporary file to store the data so we
          # can upload it
          temp = Tempfile.new("vagrant")
          temp.write(json)
          temp.close

          env[:machine].communicate.upload(temp.path, File.join(config.provisioning_path, "dna.json"))
        end

        class ChefError < Vagrant::Errors::VagrantError
          error_namespace("vagrant.provisioners.chef")
        end

         # This is the configuration which is available through `config.chef`
        class Config < Vagrant.plugin("1", :config)
          # Shared config
          attr_accessor :node_name
          attr_accessor :provisioning_path
          attr_accessor :log_level
          attr_accessor :json
          attr_accessor :http_proxy
          attr_accessor :http_proxy_user
          attr_accessor :http_proxy_pass
          attr_accessor :https_proxy
          attr_accessor :https_proxy_user
          attr_accessor :https_proxy_pass
          attr_accessor :no_proxy
          attr_accessor :binary_path
          attr_accessor :binary_env
          attr_accessor :attempts
          attr_accessor :arguments
          attr_writer :run_list

          # Provide defaults in such a way that they won't override the instance
          # variable. This is so merging continues to work properly.
          def attempts; @attempts || 1; end
          def json; @json ||= {}; end
          def log_level; @log_level || :info; end

          # This returns the json that is merged with the defaults and the
          # user set data.
          def merged_json
            original = { :instance_role => "vagrant" }
            original[:run_list] = @run_list if @run_list
            original.merge(json || {})
          end

          # Returns the run list, but also sets it up to be empty if it
          # hasn't been defined already.
          def run_list
            @run_list ||= []
          end

          # Adds a recipe to the run list
          def add_recipe(name)
            name = "recipe[#{name}]" unless name =~ /^recipe\[(.+?)\]$/
              run_list << name
          end

          # Adds a role to the run list
          def add_role(name)
            name = "role[#{name}]" unless name =~ /^role\[(.+?)\]$/
              run_list << name
          end

          def validate(env, errors)
            super

            errors.add(I18n.t("vagrant.config.chef.vagrant_as_json_key")) if json.has_key?(:vagrant)
          end

          def instance_variables_hash
            # Overridden so that the 'json' key could be removed, since its just
            # merged into the config anyways
            result = super
            result.delete("json")
            result
          end
        end
      end
    end
  end
end
