require "log4r"

require 'childprocess'

require "vagrant/util/file_mode"
require "vagrant/util/platform"
require "vagrant/util/safe_exec"
require "vagrant/util/safe_puts"
require "vagrant/util/subprocess"
require "vagrant/util/which"

module Vagrant
  module Util
    # This is a class that has helpers on it for dealing with SSH. These
    # helpers don't depend on any part of Vagrant except what is given
    # via the parameters.
    class SSH
      extend SafePuts

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
        return if Platform.windows? || Platform.wsl_windows_access_bypass?(key_path)

        LOGGER.debug("Checking key permissions: #{key_path}")
        stat = key_path.stat

        if !stat.owned? && Process.uid != 0
          # The SSH key must be owned by ourselves, unless we're root
          raise Errors::SSHKeyBadOwner, key_path: key_path
        end

        if FileMode.from_octal(stat.mode) != "600"
          LOGGER.info("Attempting to correct key permissions to 0600")
          key_path.chmod(0600)

          # Re-stat the file to get the new mode, and verify it worked
          stat = key_path.stat
          if FileMode.from_octal(stat.mode) != "600"
            raise Errors::SSHKeyBadPermissions, key_path: key_path
          end
        end
      rescue Errno::EPERM
        # This shouldn't happen since we verify we own the file, but
        # it is possible in theory, so we raise an error.
        raise Errors::SSHKeyBadPermissions, key_path: key_path
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
        # Ensure the platform supports ssh. On Windows there are several programs which
        # include ssh, notably git, mingw and cygwin, but make sure ssh is in the path!
        ssh_path = Which.which("ssh")
        if !ssh_path
          if Platform.windows?
            raise Errors::SSHUnavailableWindows,
              host: ssh_info[:host],
              port: ssh_info[:port],
              username: ssh_info[:username],
              key_path: ssh_info[:private_key_path].join(", ")
          end

          raise Errors::SSHUnavailable
        end

        # On Windows, we need to detect whether SSH is actually "plink"
        # underneath the covers. In this case, we tell the user.
        if Platform.windows?
          r = Subprocess.execute(ssh_path)
          if r.stdout.include?("PuTTY Link") || r.stdout.include?("Plink: command-line connection utility")
            raise Errors::SSHIsPuttyLink,
              host: ssh_info[:host],
              port: ssh_info[:port],
              username: ssh_info[:username],
              key_path: ssh_info[:private_key_path].join(", ")
          end
        end

        # If plain mode is enabled then we don't do any authentication (we don't
        # set a user or an identity file)
        plain_mode = opts[:plain_mode]

        options = {}
        options[:host] = ssh_info[:host]
        options[:port] = ssh_info[:port]
        options[:username] = ssh_info[:username]
        options[:private_key_path] = ssh_info[:private_key_path]

        log_level = ssh_info[:log_level] || "FATAL"

        # Command line options
        command_options = [
          "-p", options[:port].to_s,
          "-o", "LogLevel=#{log_level}"]

        if ssh_info[:compression]
          command_options += ["-o", "Compression=yes"]
        end

        if ssh_info[:dsa_authentication]
          command_options += ["-o", "DSAAuthentication=yes"]
        end

        # Solaris/OpenSolaris/Illumos uses SunSSH which doesn't support the
        # IdentitiesOnly option. Also, we don't enable it in plain mode or if
        # if keys_only is false so that SSH and Net::SSH properly search our identities
        # and tries to do it itself.
        if !Platform.solaris? && !plain_mode && ssh_info[:keys_only]
          command_options += ["-o", "IdentitiesOnly=yes"]
        end

        # no strict hostkey checking unless paranoid
        if ! ssh_info[:paranoid]
          command_options += [
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null"]
        end

        # If we're not in plain mode and :private_key_path is set attach the private key path(s).
        if !plain_mode && options[:private_key_path]
          options[:private_key_path].each do |path|

            # Use '-o' instead of '-i' because '-i' does not call
            # percent_expand in misc.c, but '-o' does. when passing the path,
            # replace '%' in the path with '%%' to escape the '%'
            path = path.to_s.gsub('%', '%%')
            command_options += ["-o", "IdentityFile=\"#{path}\""]
          end
        end

        if ssh_info[:forward_x11]
          # Both are required so that no warnings are shown regarding X11
          command_options += [
            "-o", "ForwardX11=yes",
            "-o", "ForwardX11Trusted=yes"]
        end

        if ssh_info[:proxy_command]
          command_options += ["-o", "ProxyCommand=#{ssh_info[:proxy_command]}"]
        end

        if ssh_info[:forward_env]
          command_options += ["-o", "SendEnv=#{ssh_info[:forward_env].join(" ")}"]
        end

        # Configurables -- extra_args should always be last due to the way the
        # ssh args parser works. e.g. if the user wants to use the -t option,
        # any shell command(s) she'd like to run on the remote server would
        # have to be the last part of the 'ssh' command:
        #
        #   $ ssh localhost -t -p 2222 "cd mydirectory; bash"
        #
        # Without having extra_args be last, the user loses this ability
        command_options += ["-o", "ForwardAgent=yes"] if ssh_info[:forward_agent]

        # Note about :extra_args
        #   ssh_info[:extra_args] comes from a machines ssh config in a Vagrantfile,
        #   where as opts[:extra_args] comes from running the ssh command
        command_options += Array(ssh_info[:extra_args]) if ssh_info[:extra_args]

        command_options.concat(opts[:extra_args]) if opts[:extra_args]

        # Build up the host string for connecting
        host_string = options[:host]
        host_string = "#{options[:username]}@#{host_string}" if !plain_mode
        command_options.unshift(host_string)

        # On Cygwin we want to get rid of any DOS file warnings because
        # we really don't care since both work.
        ENV["nodosfilewarning"] = "1" if Platform.cygwin?

        ssh = ssh_info[:ssh_command] || 'ssh'

        # Invoke SSH with all our options
        if !opts[:subprocess]
          LOGGER.info("Invoking SSH: #{ssh} #{command_options.inspect}")
          SafeExec.exec(ssh, *command_options)
          return
        end

        # If we're still here, it means we're supposed to subprocess
        # out to ssh rather than exec it.
        LOGGER.info("Executing SSH in subprocess: #{ssh} #{command_options.inspect}")
        process = ChildProcess.build(ssh, *command_options)
        process.io.inherit!

        # Forward configured environment variables.
        if ssh_info[:forward_env]
          ssh_info[:forward_env].each do |key|
            process.environment[key] = ENV[key]
          end
        end

        process.start
        process.wait
        return process.exit_code
      end
    end
  end
end
