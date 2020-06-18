require 'mime'
require "tmpdir"

module Vagrant
  module Action
    module Builtin
      class CloudInitSetup
        TEMP_PREFIX = "vagrant-cloud-init-iso-temp-".freeze
        TEMP_ROOT   = "/tmp".freeze

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::cloudinit::setup")
        end

        def call(env)
          machine = env[:machine]

          user_data_configs = machine.config.vm.cloud_init_configs
                                                  .select { |c| c.type == :user_data }

          setup_user_data(machine, env, user_data_configs)

          # Continue On
          @app.call(env)
        end

        # @param [Vagrant::Machine] machine
        # @param [Vagrant::Environment] env
        # @param [Array<#VagrantPlugins::Kernel_V2::VagrantConfigCloudInit>] user_data_cfgs
        def setup_user_data(machine, env, user_data_cfgs)
          return if user_data_cfgs.empty?

          machine.ui.info(I18n.t("vagrant.actions.vm.cloud_init_user_data_setup"))

          text_cfgs = []
          user_data_cfgs.each do |cfg|
            text_cfgs << read_text_cfg(machine, cfg)
          end

          msg = generate_cfg_msg(machine, text_cfgs)
          iso_path = write_cfg_iso(machine, env, msg)

          attach_disk_config(machine, env, iso_path)
        end

        # Reads an individual cloud_init config and stores its contents and the
        # content_type as a MIME text
        #
        # @param [Vagrant::Machine] machine
        # @param [VagrantPlugins::Kernel_V2::VagrantConfigCloudInit] cfg
        # @return [MIME::Text] text_msg
        def read_text_cfg(machine, cfg)
          if cfg.path
            text = File.read(Pathname.new(cfg.path).expand_path(machine.env.root_path))
          else
            text = cfg.inline
          end

          # Note: content_type must remove the leading `text/` because
          # the MIME::Text initializer hardcodes `text/` already to the type.
          # We assume content_type is correct due to the validation step
          # in VagrantConfigCloudInit.
          content_type = cfg.content_type.split('/')
          text_msg = MIME::Text.new(text, content_type[1])

          text_msg
        end

        # Combines all known cloud_init configs into a multipart mixed MIME text
        # message
        #
        # @param [Vagrant::Machine] machine
        # @param [Array<MIME::Text>] text_msg - One or more text configs
        # @return [MIME::Multipart::Mixed] msg
        def generate_cfg_msg(machine, text_cfgs)
          msg = MIME::Multipart::Mixed.new

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
        # @param [MIME::Multipart::Mixed] msg
        # @return [String] iso_path
        def write_cfg_iso(machine, env, msg)
          iso_path = nil

          if env[:env].host.capability?(:create_iso)
            # TODO: make temp_root configurable?
            source_dir = Pathname.new(Dir.mktmpdir(TEMP_PREFIX, TEMP_ROOT))
            # write a cloud.cfg file with msg.to_s
            File.open("#{source_dir}/user-data", 'w') { |file| file.write(msg.to_s) }

            iso_path = env[:env].host.capability(:create_iso, env[:env], source_dir)
          else
            raise Errors::CreateIsoHostCapNotFound
          end

          iso_path
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
          machine.config.vm.disks.map { |d| d.finalize! if d.type == :dvd && d.file == iso_path }
        end
      end
    end
  end
end
