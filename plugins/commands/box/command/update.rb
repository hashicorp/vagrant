require 'optparse'

require_relative 'download_mixins'

module VagrantPlugins
  module CommandBox
    module Command
      class Update < Vagrant.plugin("2", :command)
        include DownloadMixins

        def execute
          options = {}
          download_options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant box update [options]"
            o.separator ""
            o.separator "Updates the box that is in use in the current Vagrant environment,"
            o.separator "if there any updates available. This does not destroy/recreate the"
            o.separator "machine, so you'll have to do that to see changes."
            o.separator ""
            o.separator "To update a specific box (not tied to a Vagrant environment), use the"
            o.separator "--box flag."
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("--box BOX", String, "Update a specific box") do |b|
              options[:box] = b
            end

            o.on("--provider PROVIDER", String, "Update box with specific provider") do |p|
              options[:provider] = p.to_sym
            end

            o.on("-f", "--force", "Overwrite an existing box if it exists") do |f|
              options[:force] = f
            end

            build_download_options(o, download_options)
          end

          argv = parse_options(opts)
          return if !argv

          if options[:box]
            update_specific(options[:box], options[:provider], download_options, options[:force])
          else
            update_vms(argv, options[:provider], download_options, options[:force])
          end

          0
        end

        def update_specific(name, provider, download_options, force)
          boxes = {}
          @env.boxes.all.each do |n, v, p|
            boxes[n] ||= {}
            boxes[n][p] ||= []
            boxes[n][p] << v
          end

          if !boxes[name]
            raise Vagrant::Errors::BoxNotFound, name: name.to_s
          end

          if !provider
            if boxes[name].length > 1
              raise Vagrant::Errors::BoxUpdateMultiProvider,
                name: name.to_s,
                providers: boxes[name].keys.map(&:to_s).sort.join(", ")
            end

            provider = boxes[name].keys.first
          elsif !boxes[name][provider]
            raise Vagrant::Errors::BoxNotFoundWithProvider,
              name: name.to_s,
              provider: provider.to_s,
              providers: boxes[name].keys.map(&:to_s).sort.join(", ")
          end

          to_update = [
            [name, provider, boxes[name][provider].sort.last],
          ]

          to_update.each do |n, p, v|
            box = @env.boxes.find(n, p, v)
            box_update(box, "> #{v}", @env.ui, download_options, force)
          end
        end

        def update_vms(argv, provider, download_options, force)
          machines = {}

          with_target_vms(argv, provider: provider) do |machine|
            if !machine.config.vm.box
              machine.ui.output(I18n.t(
                "vagrant.errors.box_update_no_name"))
              next
            end

            if !machine.box
              machine.ui.output(I18n.t(
                "vagrant.errors.box_update_no_box",
                name: machine.config.vm.box))
              next
            end

            name     = machine.box.name
            provider = machine.box.provider
            version  = machine.config.vm.box_version || machine.box.version

            machines["#{name}_#{provider}_#{version}"] = machine
          end

          machines.each do |_, machine|
            box = machine.box
            version = machine.config.vm.box_version
            # Get download options from machine configuration if not specified
            # on the command line.
            download_options[:ca_cert] ||= machine.config.vm.box_download_ca_cert
            download_options[:ca_path] ||= machine.config.vm.box_download_ca_path
            download_options[:client_cert] ||= machine.config.vm.box_download_client_cert
            if download_options[:insecure].nil?
              download_options[:insecure] = machine.config.vm.box_download_insecure
            end
            box_update(box, version, machine.ui, download_options, force)
          end
        end

        def box_update(box, version, ui, download_options, force)
          ui.output(I18n.t("vagrant.box_update_checking", name: box.name))
          ui.detail("Latest installed version: #{box.version}")
          ui.detail("Version constraints: #{version}")
          ui.detail("Provider: #{box.provider}")

          update = box.has_update?(version, download_options: download_options)
          if !update
            ui.success(I18n.t(
              "vagrant.box_up_to_date_single",
              name: box.name, version: box.version))
            return
          end

          ui.output(I18n.t(
            "vagrant.box_updating",
            name: update[0].name,
            provider: update[2].name,
            old: box.version,
            new: update[1].version))
          @env.action_runner.run(Vagrant::Action.action_box_add, {
            box_url: box.metadata_url,
            box_provider: update[2].name,
            box_version: update[1].version,
            ui: ui,
            box_force: force,
            box_client_cert: download_options[:client_cert],
            box_download_ca_cert: download_options[:ca_cert],
            box_download_ca_path: download_options[:ca_path],
            box_download_insecure: download_options[:insecure]
          })
        end
      end
    end
  end
end
