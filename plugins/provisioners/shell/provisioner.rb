require "pathname"
require "tempfile"

require "vagrant/util/downloader"
require "vagrant/util/retryable"

module VagrantPlugins
  module Shell
    class Provisioner < Vagrant.plugin("2", :provisioner)
      include Vagrant::Util::Retryable

      def provision
        args = ""
        if config.args.is_a?(String)
          args = " #{config.args.to_s}"
        elsif config.args.is_a?(Array)
          args = config.args.map { |a| quote_and_escape(a) }
          args = " #{args.join(" ")}"
        end

        if @machine.config.vm.communicator == :winrm
          provision_winrm(args)
        else
          provision_ssh(args)
        end
      end

      protected

      # This handles outputting the communication data back to the UI
      def handle_comm(type, data)
        if [:stderr, :stdout].include?(type)
          # Output the data with the proper color based on the stream.
          color = type == :stdout ? :green : :red

          # Clear out the newline since we add one
          data = data.chomp
          return if data.empty?

          options = {}
          options[:color] = color if !config.keep_color

          @machine.ui.info(data.chomp, options)
        end
      end

      # This is the provision method called if SSH is what is running
      # on the remote end, which assumes a POSIX-style host.
      def provision_ssh(args)
        command = "chmod +x #{config.upload_path} && #{config.upload_path}#{args}"

        with_script_file do |path|
          # Upload the script to the machine
          @machine.communicate.tap do |comm|
            # Reset upload path permissions for the current ssh user
            info = nil
            retryable(on: Vagrant::Errors::SSHNotReady, tries: 3, sleep: 2) do
              info = @machine.ssh_info
              raise Vagrant::Errors::SSHNotReady if info.nil?
            end

            user = info[:username]
            comm.sudo("chown -R #{user} #{config.upload_path}",
                      error_check: false)

            comm.upload(path.to_s, config.upload_path)

            if config.name
              @machine.ui.detail(I18n.t("vagrant.provisioners.shell.running",
                                      script: "script: #{config.name}"))
            elsif config.path
              @machine.ui.detail(I18n.t("vagrant.provisioners.shell.running",
                                      script: path.to_s))
            else
              @machine.ui.detail(I18n.t("vagrant.provisioners.shell.running",
                                      script: "inline script"))
            end

            # Execute it with sudo
            comm.execute(
              command,
              sudo: config.privileged,
              error_key: :ssh_bad_exit_status_muted
            ) do |type, data|
              handle_comm(type, data)
            end
          end
        end
      end

      # This provisions using WinRM, which assumes a PowerShell
      # console on the other side.
      def provision_winrm(args)
        if @machine.guest.capability?(:wait_for_reboot)
          @machine.guest.capability(:wait_for_reboot)
        end

        with_script_file do |path|
          @machine.communicate.tap do |comm|
            # Make sure that the upload path has an extension, since
            # having an extension is critical for Windows execution
            upload_path = config.upload_path.to_s
            if File.extname(upload_path) == ""
              upload_path += File.extname(path.to_s)
            end

            # Upload it
            comm.upload(path.to_s, upload_path)

            # Calculate the path that we'll be executing
            exec_path = upload_path
            exec_path.gsub!('/', '\\')
            exec_path = "c:#{exec_path}" if exec_path.start_with?("\\")

            # Copy powershell_args from configuration
            shell_args = config.powershell_args

            # For PowerShell scripts bypass the execution policy unless already specified
            shell_args += " -ExecutionPolicy Bypass" if config.powershell_args !~ /[-\/]ExecutionPolicy/i

            # CLIXML output is kinda useless, especially on non-windows hosts
            shell_args += " -OutputFormat Text" if config.powershell_args !~ /[-\/]OutputFormat/i

            command = "#{exec_path}#{args}"
            command = "powershell #{shell_args.to_s} -file #{command}" if
              File.extname(exec_path).downcase == '.ps1'

            if config.name
              @machine.ui.detail(I18n.t("vagrant.provisioners.shell.running",
                                      script: "script: #{config.name}"))
            elsif config.path
              @machine.ui.detail(I18n.t("vagrant.provisioners.shell.runningas",
                                      local: config.path.to_s, remote: exec_path))
            else
              @machine.ui.detail(I18n.t("vagrant.provisioners.shell.running",
                                      script: "inline PowerShell script"))
            end

            # Execute it with sudo
            comm.sudo(command, elevated: config.privileged) do |type, data|
              handle_comm(type, data)
            end
          end
        end
      end

      # Quote and escape strings for shell execution, thanks to Capistrano.
      def quote_and_escape(text, quote = '"')
        "#{quote}#{text.gsub(/#{quote}/) { |m| "#{m}\\#{m}#{m}" }}#{quote}"
      end

      # This method yields the path to a script to upload and execute
      # on the remote server. This method will properly clean up the
      # script file if needed.
      def with_script_file
        ext    = nil
        script = nil

        if config.remote?
          download_path = @machine.env.tmp_path.join(
            "#{@machine.id}-remote-script")
          download_path.delete if download_path.file?

          begin
            Vagrant::Util::Downloader.new(config.path, download_path).download!
            ext    = File.extname(config.path)
            script = download_path.read
          ensure
            download_path.delete if download_path.file?
          end
        elsif config.path
          # Just yield the path to that file...
          root_path = @machine.env.root_path
          ext    = File.extname(config.path)
          script = Pathname.new(config.path).expand_path(root_path).read
        else
          # The script is just the inline code...
          ext    = ".ps1"
          script = config.inline
        end

        # Replace Windows line endings with Unix ones unless binary file
        # or we're running on Windows.
        if !config.binary && @machine.config.vm.communicator != :winrm
          script.gsub!(/\r\n?$/, "\n")
        end

        # Otherwise we have an inline script, we need to Tempfile it,
        # and handle it specially...
        file = Tempfile.new(['vagrant-shell', ext])

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
