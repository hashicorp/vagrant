# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require 'vagrant/util/mime'
require 'tmpdir'

module Vagrant
  module Action
    module Builtin
      class CloudInitSetup
        TEMP_PREFIX = "vagrant-cloud-init-iso-temp-".freeze

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::cloudinit::setup")
        end

        def call(env)
          machine = env[:machine]

          user_data_configs = machine.config.vm.cloud_init_configs
                                                  .select { |c| c.type == :user_data }

          if !user_data_configs.empty?
            user_data = setup_user_data(machine, env, user_data_configs)
            meta_data = { "instance-id" => "i-#{machine.id.split('-').join}" }

            write_cfg_iso(machine, env, user_data, meta_data)
          end

          # Continue On
          @app.call(env)
        end

        # @param [Vagrant::Machine] machine
        # @param [Vagrant::Environment] env
        # @param [Array<#VagrantPlugins::Kernel_V2::VagrantConfigCloudInit>] user_data_cfgs
        # @return [Vagrant::Util::Mime::MultiPart] user_data
        def setup_user_data(machine, env, user_data_cfgs)
          machine.ui.info(I18n.t("vagrant.actions.vm.cloud_init_user_data_setup"))

          text_cfgs = user_data_cfgs.map { |cfg| read_text_cfg(machine, cfg) }

          user_data = generate_cfg_msg(machine, text_cfgs)
          user_data
        end

        # Reads an individual cloud_init config and stores its contents and the
        # content_type as a MIME text
        #
        # @param [Vagrant::Machine] machine
        # @param [VagrantPlugins::Kernel_V2::VagrantConfigCloudInit] cfg
        # @return [Vagrant::Util::Mime::Entity] text_msg
        def read_text_cfg(machine, cfg)
          if cfg.path
            text = File.read(Pathname.new(cfg.path).expand_path(machine.env.root_path))
          else
            text = cfg.inline
          end

          text_msg = Vagrant::Util::Mime::Entity.new(text, cfg.content_type)
          text_msg.disposition = "attachment; filename=\"#{File.basename(cfg.content_disposition_filename).gsub('"', '\"')}\"" if cfg.content_disposition_filename
          text_msg
        end

        # Combines all known cloud_init configs into a multipart mixed MIME text
        # message
        #
        # @param [Vagrant::Machine] machine
        # @param [Array<Vagrant::Util::Mime::Entity>] text_msg - One or more text configs
        # @return [Vagrant::Util::Mime::Multipart] msg
        def generate_cfg_msg(machine, text_cfgs)
          msg = Vagrant::Util::Mime::Multipart.new
          msg.headers["MIME-Version"] = "1.0"

          text_cfgs.each do |c|
            msg.add(c)
          end

          msg
        end

        # Writes the contents of the guests cloud_init config to a tmp
        # dir and passes that source directory along to the host cap to be
        # written to an iso
        #
        # @param [Vagrant::Machine] machine
        # @param [Vagrant::Util::Mime::Multipart] user_data
        # @param [Hash] meta_data
        def write_cfg_iso(machine, env, user_data, meta_data)
          iso_path = nil

          if env[:env].host.capability?(:create_iso)
            begin
              source_dir = Pathname.new(Dir.mktmpdir(TEMP_PREFIX))
              File.open("#{source_dir}/user-data", 'w') { |file| file.write(user_data.to_s) }

              File.open("#{source_dir}/meta-data", 'w') { |file| file.write(meta_data.to_yaml) }

              iso_path = env[:env].host.capability(:create_iso,
                                                   source_dir, volume_id: "cidata")
              attach_disk_config(machine, env, iso_path.to_path)
            ensure
              FileUtils.remove_entry(source_dir)
            end
          else
            raise Errors::CreateIsoHostCapNotFound
          end
        end

        # Adds a new :dvd disk config with the given iso_path to be attached
        # to the guest later
        #
        # @param [Vagrant::Machine] machine
        # @param [Vagrant::Environment] env
        # @param [String] iso_path
        def attach_disk_config(machine, env, iso_path)
          @logger.info("Adding cloud_init iso '#{iso_path}' to disk config")
          machine.config.vm.disk :dvd, file: iso_path, name: "vagrant-cloud_init-disk"
          machine.config.vm.disks.each { |d| d.finalize! if d.type == :dvd && d.file == iso_path }
        end
      end
    end
  end
end
