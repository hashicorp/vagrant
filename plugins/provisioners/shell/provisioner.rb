require "pathname"
require "tempfile"

require "vagrant/util/downloader"

module VagrantPlugins
  module Shell
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def provision
        args = ""
        if config.args.is_a?(String)
          args = " #{config.args}"
        elsif config.args.is_a?(Array)
          args = config.args.map { |a| quote_and_escape(a) }
          args = " #{args.join(" ")}"
        end

        command = "chmod +x #{config.upload_path} && #{config.upload_path}#{args}"

        with_script_file do |path|
          # Upload the script to the machine
          @machine.communicate.tap do |comm|
            # Reset upload path permissions for the current ssh user
            user = @machine.ssh_info[:username]
            comm.sudo("chown -R #{user} #{config.upload_path}",
                      :error_check => false)

            comm.upload(path.to_s, config.upload_path)

            if config.path
              @machine.ui.info(I18n.t("vagrant.provisioners.shell.running",
                                      script: path.to_s))
            else
              @machine.ui.info(I18n.t("vagrant.provisioners.shell.running",
                                      script: "inline script"))
            end

            # Execute it with sudo
            comm.execute(command, sudo: config.privileged) do |type, data|
              if [:stderr, :stdout].include?(type)
                # Output the data with the proper color based on the stream.
                color = type == :stdout ? :green : :red

                options = {
                  new_line: false,
                  prefix: false,
                }
                options[:color] = color if !config.keep_color

                @machine.env.ui.info(data, options)
              end
            end
          end
        end
      end

      protected

      # Quote and escape strings for shell execution, thanks to Capistrano.
      def quote_and_escape(text, quote = '"')
        "#{quote}#{text.gsub(/#{quote}/) { |m| "#{m}\\#{m}#{m}" }}#{quote}"
      end

      # This method yields the path to a script to upload and execute
      # on the remote server. This method will properly clean up the
      # script file if needed.
      def with_script_file
        script = nil

        if config.remote?
          download_path = @machine.env.tmp_path.join("#{@machine.id}-remote-script")
          download_path.delete if download_path.file?

          Vagrant::Util::Downloader.new(config.path, download_path).download!
          script = download_path.read

          download_path.delete
        elsif config.path
          # Just yield the path to that file...
          root_path = @machine.env.root_path
          script = Pathname.new(config.path).expand_path(root_path).read
        else
          # The script is just the inline code...
          script = config.inline
        end

        # Replace Windows line endings with Unix ones unless binary file
        script.gsub!(/\r\n?$/, "\n") if !config.binary

        # Otherwise we have an inline script, we need to Tempfile it,
        # and handle it specially...
        file = Tempfile.new('vagrant-shell')

        # Unless you set binmode, on a Windows host the shell script will
        # have CRLF line endings instead of LF line endings, causing havoc
        # when the guest executes it. This fixes [GH-1181].
        file.binmode

        begin
          file.write(script)
          file.fsync
          file.close
          yield file.path
        ensure
          file.close
          file.unlink
        end
      end
    end
  end
end
