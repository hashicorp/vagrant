require "vagrant/util/safe_exec"
require "vagrant/util/subprocess"
require "vagrant/util/which"

module VagrantPlugins
  module HarmonyPush
    class Push < Vagrant.plugin("2", :push)
      UPLOADER_BIN = "harmony-upload".freeze

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
        cmd << "-vcs" if config.vcs
        cmd += config.include.map { |v| ["-include", v] }
        cmd += config.exclude.map { |v| ["-exclude", v] }
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
        uploader = config.uploader_path
        if uploader
          return uploader
        end

        if Vagrant.in_installer?
          # TODO: look up uploader in embedded dir
        else
          return Vagrant::Util::Which.which(UPLOADER_BIN)
        end
      end
    end
  end
end
