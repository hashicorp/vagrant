#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------
  module HyperV
    module WindowsProvisioner
      class Shell < VagrantPlugins::Shell::Provisioner
        attr_reader :provisioner
        def initialize(env)
          @env = env
          @provisioner = env[:provisioner]
        end

        def provision
          arguments = ""
          arguments = " #{config.args}" if config.args
          with_windows_script_file do |path|
            # Upload the script to a TMP file in remote VM
            @env[:ui].info "Copying the script to Guest"

            guest_path = if File.extname(config.upload_path) == ""
              "#{config.upload_path}#{File.extname(path.to_s)}"
            else
              config.upload_path
            end

            @env[:machine].provider.driver.upload(path, guest_path)

            @env[:ui].info "Executing the script in Guest"
            # Execute the file from remote location
            ssh_info = @env[:machine].ssh_info
            options = { :guest_ip => ssh_info[:host],
                       :username => ssh_info[:username],
                       :path => guest_path.gsub("/","\\"),
                       :vm_id => @env[:machine].id,
                       :args => arguments,
                       :password => "vagrant" }
            @env[:machine].provider.driver.execute('execute_remote_file.ps1', options) do |type, data|
              if type == :stdout || type == :stderr
                @env[:ui].info data
              end
            end
          end
        end

        protected

        def config
          provisioner.config
        end

        # This method yields the path to a script to upload and execute
        # on the remote server. This method will properly clean up the
        # script file if needed.
        def with_windows_script_file
          if config.remote?
            download_path = @env[:machine].env.tmp_path.join("#{@env[:machine].id}-remote-script#{File.extname(config.path)}")
            download_path.delete if download_path.file?

            begin
              Vagrant::Util::Downloader.new(config.path, download_path).download!
              yield download_path
            ensure
              download_path.delete
            end

          elsif config.path
            # Just yield the path to that file...
            yield config.path
          else
            # Otherwise we have an inline script, we need to Tempfile it,
            # and handle it specially...
            file = Tempfile.new(['vagrant-powershell', '.ps1'])

            begin
              file.write(config.inline)
              file.fsync
              file.close
              yield file.path
            ensure
              file.close
            end
          end
        end

        end
      end
    end
  end
