require 'optparse'

module VagrantPlugins
  module CommandBox
    module Command
      class Update < Vagrant.plugin("2", :command)
        def execute
          options = {}
          secure_options = {}

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

            o.on("--insecure", "Do not validate SSL certificates") do |i|
              secure_options[:insecure] = i
            end

            o.on("--cacert FILE", String, "CA certificate for SSL download") do |c|
              secure_options[:ca_cert] = c
            end

            o.on("--capath DIR", String, "CA certificate directory for SSL download") do |c|
              secure_options[:ca_path] = c
            end

            o.on("--cert FILE", String,
                 "A client SSL cert, if needed") do |c|
              secure_options[:client_cert] = c
            end
          end

          argv = parse_options(opts)
          return if !argv

          if options[:box]
            update_specific(options[:box], options[:provider], secure_options)
          else
            update_vms(argv, options[:provider], secure_options)
          end

          0
        end

        def update_specific(name, provider, secure_options)
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
            box_update(box, "> #{v}", @env.ui, secure_options)
          end
        end

        def update_vms(argv, provider, secure_options)
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

            box = machine.box
            version = machine.config.vm.box_version
            box_update(box, version, machine.ui, secure_options)
          end
        end

        def box_update(box, version, ui, secure_options)
          ui.output(I18n.t("vagrant.box_update_checking", name: box.name))
          ui.detail("Latest installed version: #{box.version}")
          ui.detail("Version constraints: #{version}")
          ui.detail("Provider: #{box.provider}")

          update = box.has_update?(version)
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
            box_download_ca_cert: secure_options[:ca_cert],
            box_download_ca_path: secure_options[:ca_path],
            box_download_client_cert: secure_options[:client_cert],
            box_download_insecure: secure_options[:insecure],
            ui: ui,
          })
        end
      end
    end
  end
end
