require "log4r"

require "vagrant/util/safe_puts"
require "vagrant/util/ssh"

module Vagrant
  module Util
    # This is a class that has helpers on it for dealing with SCP These
    # helpers don't depend on any part of Vagrant except what is given
    # via the parameters.
    #
    # This class extend vagrant/util/ssh.rb for file permission checks
    class SCP < SSH


      # Halts the running of this process and replaces it with SCP instance
      # that copies files to/from the remote machine.
      #
      # Note: This method NEVER returns. The process ends after this.
      #
      # @param [Hash] ssh_info This is the SSH information. For the keys
      #   required please see the documentation of {Machine#ssh_info}.
      # @param [Hash] opts These are additional options that are supported
      #   by exec.
      def self.exec(ssh_info, opts={})
        # Ensure the platform supports scp. On Windows there are several programs which
        # include scp, notably git, mingw and cygwin, but make sure scp is in the path!
        scp_path = Which.which("scp")
        if !scp_path
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
          r = Subprocess.execute(scp_path)
          if r.stdout.include?("PuTTY Link")
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
          "-P", options[:port].to_s,
          "-o", "Compression=yes",
          "-o", "DSAAuthentication=yes",
          "-o", "LogLevel=#{log_level}",
          "-o", "StrictHostKeyChecking=no",
          "-o", "UserKnownHostsFile=/dev/null"
        ]

        # Solaris/OpenSolaris/Illumos uses SunSSH which doesn't support the
        # IdentitiesOnly option. Also, we don't enable it in plain mode so
        # that SSH properly searches our identities and tries to do it itself.
        if !Platform.solaris? && !plain_mode
          command_options += ["-o", "IdentitiesOnly=yes"]
        end

        # If we're not in plain mode, attach the private key path.
        if !plain_mode
          options[:private_key_path].each do |path|
            command_options += ["-i", path.to_s]
          end
        end

        if ssh_info[:proxy_command]
          command_options += ["-o", "ProxyCommand=#{ssh_info[:proxy_command]}"]
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
        command_options.concat(opts[:extra_args]) if opts[:extra_args]

        # Build up the host string for connecting
        host_string = options[:host]
        host_string = "#{options[:username]}@#{host_string}" if !plain_mode

        src = opts[:source]
        dst = opts[:destination]

        # FIXME: Should throw a vagrant exception!
        fail ArgumentError, 'Source and Destination must be provided' if !src || !dst

        src = src.sub('vagrant', host_string) if src.start_with? 'vagrant:'
        dst = dst.sub('vagrant', host_string) if dst.start_with? 'vagrant:'

        command_options += [src, dst]

        # On Cygwin we want to get rid of any DOS file warnings because
        # we really don't care since both work.
        ENV["nodosfilewarning"] = "1" if Platform.cygwin?

        # If we're still here, it means we're supposed to subprocess
        # out to scp rather than exec it.
        LOGGER.info("Executing SCP in subprocess: #{command_options.inspect}")
        process = ChildProcess.build("scp", *command_options)
        process.io.inherit!
        process.start
        process.wait
        return process.exit_code
      end
    end
  end
end

