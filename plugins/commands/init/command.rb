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
        }

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant init [options] [name [url]]"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("-f", "--force", "Overwrite existing Vagrantfile") do |f|
            options[:force] = f
          end

          o.on("-m", "--minimal", "Create minimal Vagrantfile (no help comments)") do |m|
            options[:minimal] = m
          end

          o.on("--output FILE", String,
               "Output path for the box. '-' for stdout") do |output|
            options[:output] = output
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

        template = "templates/commands/init/Vagrantfile"
        if options[:minimal]
          template = "templates/commands/init/Vagrantfile.min"
        end

        template_path = ::Vagrant.source_root.join(template)
        contents = Vagrant::Util::TemplateRenderer.render(template_path,
                                                          box_name: argv[0] || "base",
                                                          box_url: argv[1])

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
