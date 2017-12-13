require 'optparse'

require 'vagrant/util/template_renderer'

module VagrantPlugins
  module CommandInit
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "initializes a new Vagrant environment by creating a Vagrantfile"
      end

      def execute
        options = {
          force: false,
          minimal: false,
          output: "Vagrantfile",
          template: nil
        }

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant init [options] [name [url]]"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("--box-version VERSION", "Version of the box to add") do |f|
            options[:box_version] = f
          end

          o.on("-f", "--force", "Overwrite existing Vagrantfile") do |f|
            options[:force] = f
          end

          o.on("-m", "--minimal", "Use minimal Vagrantfile template (no help comments). Ignored with --template") do |m|
            options[:minimal] = m
          end

          o.on("--output FILE", String,
               "Output path for the box. '-' for stdout") do |output|
            options[:output] = output
          end

          o.on("--template FILE", String, "Path to custom Vagrantfile template") do |template|
            options[:template] = template
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        save_path = nil
        if options[:output] != "-"
          save_path = Pathname.new(options[:output]).expand_path(@env.cwd)
          save_path.delete if save_path.exist? && options[:force]
          raise Vagrant::Errors::VagrantfileExistsError if save_path.exist?
        end

        # Determine the template and template root to use
        template_root = ""
        if options[:template].nil?
          options[:template] = "Vagrantfile"

          if options[:minimal]
            options[:template] = "Vagrantfile.min"
          end

          template_root = ::Vagrant.source_root.join("templates/commands/init")
        end

        # Strip the .erb extension off the template if the user passes it in
        options[:template] = options[:template].chomp(".erb")

        # Make sure the template actually exists
        full_template_path = Vagrant::Util::TemplateRenderer.new(options[:template], template_root: template_root).full_template_path
        if !File.file?(full_template_path)
          raise Vagrant::Errors::VagrantfileTemplateNotFoundError, path: full_template_path
        end

        contents = Vagrant::Util::TemplateRenderer.render(options[:template],
          box_name: argv[0] || "base",
          box_url: argv[1],
          box_version: options[:box_version],
          template_root: template_root
        )

        if save_path
          # Write out the contents
          begin
            save_path.open("w+") do |f|
              f.write(contents)
            end
          rescue Errno::EACCES
            raise Vagrant::Errors::VagrantfileWriteError
          end

          @env.ui.info(I18n.t("vagrant.commands.init.success"), prefix: false)
        else
          @env.ui.info(contents, prefix: false)
        end

        # Success, exit status 0
        0
      end
    end
  end
end
