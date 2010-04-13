module Vagrant
  class Commands
    class Init < Base
      Base.subcommand "init", self
      description "Initializes current folder for Vagrant usage"

      def execute(args)
        create_vagrantfile(args[0])
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant init [name]"
      end

      # Actually writes the initial Vagrantfile to the current working directory.
      # The Vagrantfile will contain the base box configuration specified, or
      # will just use "base" if none is specified.
      #
      # @param [String] default_box The default base box for this Vagrantfile
      def create_vagrantfile(default_box=nil)
        rootfile_path = File.join(Dir.pwd, Environment::ROOTFILE_NAME)
        error_and_exit(:rootfile_already_exists) if File.exist?(rootfile_path)

        # Copy over the rootfile template into this directory
        default_box ||= "base"
        File.open(rootfile_path, 'w+') do |f|
          f.write(TemplateRenderer.render(Environment::ROOTFILE_NAME, :default_box => default_box))
        end
      end
    end
  end
end