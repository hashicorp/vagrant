require "vagrant/util/safe_exec"
require "vagrant/util/subprocess"
require "vagrant/util/which"

module VagrantPlugins
  module AtlasPush
    class Push < Vagrant.plugin("2", :push)
      UPLOADER_BIN = "atlas-upload".freeze

      def push
        uploader = self.uploader_path

        # If we didn't find the uploader binary it is a critical error
        raise Errors::UploaderNotFound if !uploader

        # We found it. Build up the command and the args.
        execute(uploader)
        return 0
      end

      # Executes the uploader with the proper flags based on the configuration.
      # This function shouldn't return since it will exec, but might return
      # if we're on a system that doesn't support exec, so handle that properly.
      def execute(uploader)
        cmd = []
        cmd << "-debug" if !Vagrant.log_level.nil?
        cmd << "-vcs" if config.vcs
        cmd += config.includes.map { |v| ["-include", v] }
        cmd += config.excludes.map { |v| ["-exclude", v] }
        cmd += metadata.map { |k,v| ["-metadata", "#{k}=#{v}"] }
        cmd += ["-address", config.address] if config.address
        cmd += ["-token", config.token] if config.token
        cmd << config.app
        cmd << File.expand_path(config.dir, env.root_path)
        Vagrant::Util::SafeExec.exec(uploader, *cmd.flatten)
      end

      # This returns the path to the uploader binary, or nil if it can't
      # be found.
      #
      # @return [String]
      def uploader_path
        # Determine the uploader path
        if uploader = config.uploader_path
          return uploader
        end

        if Vagrant.in_installer?
          path = File.join(
            Vagrant.installer_embedded_dir, "bin", UPLOADER_BIN)
          return path if File.file?(path)
        end

        return Vagrant::Util::Which.which(UPLOADER_BIN)
      end

      # The metadata command for this push.
      #
      # @return [Array<String>]
      def metadata
        box     = env.vagrantfile.config.vm.box
        box_url = env.vagrantfile.config.vm.box_url

        result = {}

        if !box.nil? && !box.empty?
          result["box"] = box
        end

        if !box_url.nil? && !box_url.empty?
          result["box_url"] = Array(box_url).first
        end

        return result
      end
    end
  end
end
