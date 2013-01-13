require "pathname"
require "tempfile"

module VagrantPlugins
  module Shell
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def provision
        args = ""
        args = " #{config.args}" if config.args
        command = "chmod +x #{config.upload_path} && #{config.upload_path}#{args}"

        with_script_file do |path|
          # Upload the script to the machine
          @machine.communicate.tap do |comm|
            comm.upload(path.to_s, config.upload_path)

            # Execute it with sudo
            comm.sudo(command) do |type, data|
              if [:stderr, :stdout].include?(type)
                # Output the data with the proper color based on the stream.
                color = type == :stdout ? :green : :red

                # Note: Be sure to chomp the data to avoid the newlines that the
                # Chef outputs.
                @machine.env.ui.info(data.chomp, :color => color, :prefix => false)
              end
            end
          end
        end
      end

      protected

      # This method yields the path to a script to upload and execute
      # on the remote server. This method will properly clean up the
      # script file if needed.
      def with_script_file
        if config.path
          # Just yield the path to that file...
          root_path = @machine.env.root_path
          yield Pathname.new(config.path).expand_path(root_path)
          return
        end

        # Otherwise we have an inline script, we need to Tempfile it,
        # and handle it specially...
        file = Tempfile.new('vagrant-shell')

        # Unless you set binmode, on a Windows host the shell script will
        # have CRLF line endings instead of LF line endings, causing havoc
        # when the guest executes it. This fixes [GH-1181].
        file.binmode

        begin
          file.write(config.inline)
          file.fsync
          yield file.path
        ensure
          file.close
          file.unlink
        end
      end
    end
  end
end
