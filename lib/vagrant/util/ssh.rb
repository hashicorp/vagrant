require "log4r"

require "vagrant/util/file_mode"
require "vagrant/util/platform"
require "vagrant/util/safe_exec"

module Vagrant
  module Util
    # This is a class that has helpers on it for dealing with SSH. These
    # helpers don't depend on any part of Vagrant except what is given
    # via the parameters.
    class SSH
      LOGGER = Log4r::Logger.new("vagrant::util::ssh")

      # Checks that the permissions for a private key are valid, and fixes
      # them if possible. SSH requires that permissions on the private key
      # are 0600 on POSIX based systems. This will make a best effort to
      # fix these permissions if they are not properly set.
      #
      # @param [Pathname] key_path The path to the private key.
      def self.check_key_permissions(key_path)
        # Don't do anything if we're on Windows, since Windows doesn't worry
        # about key permissions.
        return if Platform.windows?

        LOGGER.debug("Checking key permissions: #{key_path}")
        stat = key_path.stat

        if stat.owned? && FileMode.from_octal(stat.mode) != "600"
          LOGGER.info("Attempting to correct key permissions to 0600")
          key_path.chmod(0600)

          # Re-stat the file to get the new mode, and verify it worked
          stat = key_path.stat
          if FileMode.from_octal(stat.mode) != "600"
            raise Errors::SSHKeyBadPermissions, :key_path => key_path
          end
        end
      rescue Errno::EPERM
        # This shouldn't happen since we verify we own the file, but
        # it is possible in theory, so we raise an error.
        raise Errors::SSHKeyBadPermissions, :key_path => key_path
      end

      # Halts the running of this process and replaces it with a full-fledged
      # SSH shell into a remote machine.
      #
      # Note: This method NEVER returns. The process ends after this.
      #
      # @param [Hash] ssh_info This is the SSH information. For the keys
      #   required please see the documentation of {Machine#ssh_info}.
      # @param [Hash] opts These are additional options that are supported
      #   by exec.
      def self.exec(ssh_info, opts={})
        # If we're running Windows, raise an exception since we currently
        # still don't support exec-ing into SSH. In the future this should
        # certainly be possible if we can detect we're in an environment that
        # supports it.
        if Platform.windows?
          raise Errors::SSHUnavailableWindows,
            :host => ssh_info[:host],
            :port => ssh_info[:port],
            :username => ssh_info[:username],
            :key_path => ssh_info[:private_key_path]
        end

        # Verify that we have SSH available on the system.
        raise Errors::SSHUnavailable if !Kernel.system("which ssh > /dev/null 2>&1")

        # If plain mode is enabled then we don't do any authentication (we don't
        # set a user or an identity file)
        plain_mode = opts[:plain_mode]

        options = {}
        options[:host] = ssh_info[:host]
        options[:port] = ssh_info[:port]
        options[:username] = ssh_info[:username]
        options[:private_key_path] = ssh_info[:private_key_path]

        # Command line options
        command_options = [
          "-p", options[:port].to_s,
          "-o", "LogLevel=FATAL",
          "-o", "StrictHostKeyChecking=no",
          "-o", "UserKnownHostsFile=/dev/null"]

        # Configurables
        command_options += ["-o", "ForwardAgent=yes"] if ssh_info[:forward_agent]
        command_options.concat(opts[:extra_args]) if opts[:extra_args]

        # Solaris/OpenSolaris/Illumos uses SunSSH which doesn't support the
        # IdentitiesOnly option. Also, we don't enable it in plain mode so
        # that SSH properly searches our identities and tries to do it itself.
        if !Platform.solaris? && !plain_mode
          command_options += ["-o", "IdentitiesOnly=yes"]
        end

        # If we're not in plain mode, attach the private key path.
        command_options += ["-i", options[:private_key_path].to_s] if !plain_mode

        if ssh_info[:forward_x11]
          # Both are required so that no warnings are shown regarding X11
          command_options += [
            "-o", "ForwardX11=yes",
            "-o", "ForwardX11Trusted=yes"]
        end

        # Build up the host string for connecting
        host_string = options[:host]
        host_string = "#{options[:username]}@#{host_string}" if !plain_mode
        command_options << host_string

        # Invoke SSH with all our options
        LOGGER.info("Invoking SSH: #{command_options.inspect}")
        SafeExec.exec("ssh", *command_options)
      end
    end
  end
end
