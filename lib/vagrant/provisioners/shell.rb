module Vagrant
  module Provisioners
    class Shell < Base
      class Config < Vagrant::Config::Base
        attr_accessor :inline
        attr_accessor :path
        attr_accessor :upload_path
        attr_accessor :args

        def initialize
          @inline = nil
          @path = nil
          @upload_path = "/tmp/vagrant-shell"
          @args = nil
        end

        def validate(env, errors)
          super

          # Validate that the parameters are properly set
          if path && inline
            errors.add(I18n.t("vagrant.provisioners.shell.path_and_inline_set"))
          elsif !path && !inline
            errors.add(I18n.t("vagrant.provisioners.shell.no_path_or_inline"))
          end

          # Validate the existence of a script to upload
          if path
            expanded_path = Pathname.new(path).expand_path(env.root_path)
            if !expanded_path.file?
              errors.add(I18n.t("vagrant.provisioners.shell.path_invalid",
                                :path => expanded_path))
            end
          end

          # There needs to be a path to upload the script to
          if !upload_path
            errors.add(I18n.t("vagrant.provisioners.shell.upload_path_not_set"))
          end

          # If there are args and its not a string, that is a problem
          if args && !args.is_a?(String)
            errors.add(I18n.t("vagrant.provisioners.shell.args_not_string"))
          end
        end
      end

      def self.config_class
        Config
      end

      # This method yields the path to a script to upload and execute
      # on the remote server. This method will properly clean up the
      # script file if needed.
      def with_script_file
        if config.path
          # Just yield the path to that file...
          yield Pathname.new(config.path).expand_path(env[:root_path])
          return
        end

        # Otherwise we have an inline script, we need to Tempfile it,
        # and handle it specially...
        file = Tempfile.new('vagrant-shell')
        begin
          file.write(config.inline)
          file.fsync
          yield file.path
        ensure
          file.close
          file.unlink
        end
      end

      def provision!
        args = ""
        args = " #{config.args}" if config.args
        commands = ["chmod +x #{config.upload_path}", "#{config.upload_path}#{args}"]

        with_script_file do |path|
          # Upload the script to the VM
          env[:vm].ssh.upload!(path.to_s, config.upload_path)

          # Execute it with sudo
          env[:vm].ssh.execute do |ssh|
            ssh.sudo!(commands) do |ch, type, data|
              if type == :exit_status
                ssh.check_exit_status(data, commands)
              else
                # Output the data with the proper color based on the stream.
                color = type == :stdout ? :green : :red

                # Note: Be sure to chomp the data to avoid the newlines that the
                # Chef outputs.
                env[:ui].info(data.chomp, :color => color, :prefix => false)
              end
            end
          end
        end
      end
    end
  end
end
