require "tempfile"

require "vagrant/util/template_renderer"

module VagrantPlugins
  module Chef
    class CommandBuilderWindows < CommandBuilder
      def build_command
        binary_path = "chef-#{@client_type}"
        if @config.binary_path
          binary_path = File.join(@config.binary_path, binary_path)
          binary_path.gsub!("/", "\\")
          binary_path = "c:#{binary_path}" if binary_path.start_with?("\\")
        end

        chef_arguments = "-c #{provisioning_path("#{@client_type}.rb")}"
        chef_arguments << " -j #{provisioning_path("dna.json")}"
        chef_arguments << " #{@config.arguments}" if @config.arguments

        command_env = ""
        command_env = "#{@config.binary_env} " if @config.binary_env

        task_ps1_path = provisioning_path("cheftask.ps1")

        opts = {
          user: @machine.config.winrm.username,
          pass: @machine.config.winrm.password,
          chef_arguments: chef_arguments,
          chef_binary_path: "#{command_env}#{binary_path}",
          chef_stdout_log: provisioning_path("chef-#{@client_type}.log"),
          chef_stderr_log: provisioning_path("chef-#{@client_type}.err.log"),
          chef_task_exitcode: provisioning_path('cheftask.exitcode'),
          chef_task_running: provisioning_path('cheftask.running'),
          chef_task_ps1: task_ps1_path,
          chef_task_run_ps1: provisioning_path('cheftaskrun.ps1'),
          chef_task_xml: provisioning_path('cheftask.xml'),
        }

        # Upload the files we'll need
        render_and_upload(
          "cheftaskrun.ps1", opts[:chef_task_run_ps1], opts)
        render_and_upload(
          "cheftask.xml", opts[:chef_task_xml], opts)
        render_and_upload(
          "cheftask.ps1", opts[:chef_task_ps1], opts)

        return <<-EOH
        $old = Get-ExecutionPolicy;
        Set-ExecutionPolicy Unrestricted -force;
        #{task_ps1_path};
        Set-ExecutionPolicy $old -force
        EOH
      end

      protected

      def provisioning_path(file)
        path = "#{@config.provisioning_path}/#{file}"
        path.gsub!("/", "\\")
        path = "c:#{path}" if path.start_with?("\\")
        path
      end

      def render_and_upload(template, dest, opts)
        path = File.expand_path("../scripts/#{template}", __FILE__)
        data = Vagrant::Util::TemplateRenderer.render(path, options)

        file = Tempfile.new("vagrant-chef")
        file.binmode
        file.write(data)
        file.fsync
        file.close

        @machine.communicate.upload(file.path, dest)
      ensure
        if file
          file.close
          file.unlink
        end
      end
    end
  end
end
