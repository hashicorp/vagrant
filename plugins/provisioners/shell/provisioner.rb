require "pathname"
require "tempfile"

require "vagrant/util/downloader"
require "vagrant/util/retryable"

module VagrantPlugins
  module Shell
    class Provisioner < Vagrant.plugin("2", :provisioner)
      include Vagrant::Util::Retryable

      DEFAULT_WINDOWS_SHELL_EXT = ".ps1".freeze

      CMD_WINDOWS_SHELL_EXT = ".bat".freeze

      def provision
        args = ""
        if config.args.is_a?(String)
          args = " #{config.args.to_s}"
        elsif config.args.is_a?(Array)
          args = config.args.map { |a| quote_and_escape(a) }
          args = " #{args.join(" ")}"
        end

        # In cases where the connection is just being reset
        # bail out before attempting to do any actual provisioning
        return if !config.path && !config.inline

        case @machine.config.vm.communicator
        when :winrm
          provision_winrm(args)
        when :winssh
          provision_winssh(args)
        else
          provision_ssh(args)
        end
      ensure
        if config.reboot
          @machine.guest.capability(:reboot)
        else
          @machine.communicate.reset! if config.reset
        end
      end

      def upload_path
        if !defined?(@_upload_path)
          case @machine.config.vm.guest
          when :windows
            @_upload_path = Vagrant::Util::Platform.unix_windows_path(config.upload_path.to_s)
          else
            @_upload_path = config.upload_path.to_s
          end

          if @_upload_path.empty?
            case @machine.config.vm.guest
            when :windows
              @_upload_path = "C:/tmp/vagrant-shell"
            else
              @_upload_path = "/tmp/vagrant-shell"
            end
          end
        end
        @_upload_path
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

          @machine.ui.detail(data.chomp, options)
        end
      end

      # This is the provision method called if SSH is what is running
      # on the remote end, which assumes a POSIX-style host.
      def provision_ssh(args)
        env = config.env.map { |k,v| "#{k}=#{quote_and_escape(v.to_s)}" }
        env = env.join(" ")

        command =  "chmod +x '#{upload_path}'"
        command << " &&"
        command << " #{env}" if !env.empty?
        command << " #{upload_path}#{args}"

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
            comm.sudo("chown -R #{user} #{upload_path}",
                      error_check: false)

            comm.upload(path.to_s, upload_path)

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

      # This is the provision method called if Windows OpenSSH is what is running
      # on the remote end, which assumes a non-POSIX-style host.
      def provision_winssh(args)
        with_script_file do |path|
          # Upload the script to the machine
          @machine.communicate.tap do |comm|
            env = config.env.map{|k,v| comm.generate_environment_export(k, v)}.join(';')

            remote_ext = get_windows_ext(path)
            remote_path = add_extension(upload_path, remote_ext)

            if remote_ext == ".bat"
              command = "#{env}\n cmd.exe /c \"#{remote_path}\" #{args}"
            else
              # Copy powershell_args from configuration
              shell_args = config.powershell_args
              # For PowerShell scripts bypass the execution policy unless already specified
              shell_args += " -ExecutionPolicy Bypass" if config.powershell_args !~ /[-\/]ExecutionPolicy/i
              # CLIXML output is kinda useless, especially on non-windows hosts
              shell_args += " -OutputFormat Text" if config.powershell_args !~ /[-\/]OutputFormat/i
              command = "#{env}\npowershell #{shell_args} -file \"#{remote_path}\"#{args}"
            end

            # Reset upload path permissions for the current ssh user
            info = nil
            retryable(on: Vagrant::Errors::SSHNotReady, tries: 3, sleep: 2) do
              info = @machine.ssh_info
              raise Vagrant::Errors::SSHNotReady if info.nil?
            end
            
            comm.upload(path.to_s, remote_path)

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
              shell: :powershell,
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
            winrm_upload_path = add_extension(upload_path,  get_windows_ext(path))

            # Upload it
            comm.upload(path.to_s, winrm_upload_path)

            # Build the environment
            env = config.env.map { |k,v| "$env:#{k} = #{quote_and_escape(v.to_s)}" }
            env = env.join("; ")

            # Calculate the path that we'll be executing
            exec_path = winrm_upload_path
            exec_path.gsub!('/', '\\')
            exec_path = "c:#{exec_path}" if exec_path.start_with?("\\")

            # Copy powershell_args from configuration
            shell_args = config.powershell_args

            # For PowerShell scripts bypass the execution policy unless already specified
            shell_args += " -ExecutionPolicy Bypass" if config.powershell_args !~ /[-\/]ExecutionPolicy/i

            # CLIXML output is kinda useless, especially on non-windows hosts
            shell_args += " -OutputFormat Text" if config.powershell_args !~ /[-\/]OutputFormat/i

            command = "\"#{exec_path}\"#{args}"
            if File.extname(exec_path).downcase == ".ps1"
              command = "powershell #{shell_args.to_s} -file #{command}"
            else
              command = "cmd /q /c #{command}"
            end

            # Append the environment
            if !env.empty?
              command = "#{env}; #{command}"
            end

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
            comm.sudo(command, { elevated: config.privileged, interactive: config.powershell_elevated_interactive }) do |type, data|
              handle_comm(type, data)
            end
          end
        end
      end

      # Quote and escape strings for shell execution, thanks to Capistrano.
      def quote_and_escape(text, quote = '"')
        "#{quote}#{text.gsub(/#{quote}/) { |m| "#{m}\\#{m}#{m}" }}#{quote}"
      end

      def add_extension(path, ext)
        return path if !File.extname(path.to_s).empty?
        path + ext
      end

      def get_windows_ext(path)
        remote_ext = File.extname(upload_path.to_s)
        if remote_ext.empty?
          remote_ext = File.extname(path.to_s)
          if remote_ext.empty?
            remote_ext = @machine.config.winssh.shell == "cmd" ? CMD_WINDOWS_SHELL_EXT : DEFAULT_WINDOWS_SHELL_EXT
          end
        end
        remote_ext
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
            Vagrant::Util::Downloader.new(
              config.path,
              download_path,
              md5: config.md5,
              sha1: config.sha1,
              sha256: config.sha256,
              sha384: config.sha384,
              sha512: config.sha512
            ).download!
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
          script = config.inline
        end

        # Replace Windows line endings with Unix ones unless binary file
        # or we're running on Windows.
        if !config.binary && @machine.config.vm.guest != :windows
          begin
            script = script.gsub(/\r\n?$/, "\n")
          rescue ArgumentError
            script = script.force_encoding("ASCII-8BIT").gsub(/\r\n?$/, "\n")
          end
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
