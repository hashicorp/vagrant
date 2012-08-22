require "fileutils"
require "pathname"

require "log4r"
require "childprocess"

require "vagrant/util/subprocess"

require "acceptance/support/virtualbox"
require "support/isolated_environment"

module Acceptance
  # This class manages an isolated environment for Vagrant to
  # run in. It creates a temporary directory to act as the
  # working directory as well as sets a custom home directory.
  class IsolatedEnvironment < ::IsolatedEnvironment
    SKELETON_DIR = Pathname.new(File.expand_path("../../skeletons", __FILE__))

    def initialize(apps=nil, env=nil)
      super()

      @logger = Log4r::Logger.new("test::acceptance::isolated_environment")

      @apps = apps.clone || {}
      @env  = env.clone || {}

      # Set the home directory and virtualbox home directory environmental
      # variables so that Vagrant and VirtualBox see the proper paths here.
      @env["HOME"] ||= @homedir.to_s
      @env["VBOX_USER_HOME"] ||= @homedir.to_s
    end

    # Copies a skeleton into this isolated environment. This is useful
    # for testing environments that require a complex setup.
    #
    # @param [String] name Name of the skeleton in the skeletons/ directory.
    def skeleton!(name)
      # Copy all the files into the home directory
      source = Dir.glob(SKELETON_DIR.join(name).join("*").to_s)
      FileUtils.cp_r(source, @workdir.to_s)
    end

    # Executes a command in the context of this isolated environment.
    # Any command executed will therefore see our temporary directory
    # as the home directory.
    def execute(command, *argN)
      # Create the command
      command = replace_command(command)

      # Determine the options
      options = argN.last.is_a?(Hash) ? argN.pop : {}
      options = {
        :workdir => @workdir,
        :env     => @env,
        :notify  => [:stdin, :stderr, :stdout]
      }.merge(options)

      # Add the options to be passed on
      argN << options

      # Execute, logging out the stdout/stderr as we get it
      @logger.info("Executing: #{[command].concat(argN).inspect}")
      Vagrant::Util::Subprocess.execute(command *argN) do |type, data|
        @logger.debug("#{type}: #{data}") if type == :stdout || type == :stderr
        yield type, data if block_given?
      end
    end

    # Closes the environment, cleans up the temporary directories, etc.
    def close
      # Only delete virtual machines if VBoxSVC is running, meaning
      # that something related to VirtualBox started running in this
      # environment.
      delete_virtual_machines if VirtualBox.find_vboxsvc

      # Let the parent handle cleaning up
      super
    end

    def delete_virtual_machines
      # Delete all virtual machines
      @logger.debug("Finding all virtual machines")
      execute("VBoxManage", "list", "vms").stdout.lines.each do |line|
        data = /^"(?<name>.+?)" {(?<uuid>.+?)}$/.match(line)

        begin
          @logger.debug("Removing VM: #{data[:name]}")

          # We add a timeout onto this because sometimes for seemingly no
          # reason it will simply freeze, although the VM is successfully
          # "aborted." The timeout gets around this strange behavior.
          execute("VBoxManage", "controlvm", data[:uuid], "poweroff", :timeout => 5)
        rescue Vagrant::Util::Subprocess::TimeoutExceeded => e
          @logger.info("Failed to poweroff VM '#{data[:uuid]}'. Killing process.")

          # Kill the process and wait a bit for it to disappear
          Process.kill('KILL', e.pid)
          Process.waitpid2(e.pid)
        end

        sleep 0.5

        result = execute("VBoxManage", "unregistervm", data[:uuid], "--delete")
        raise Exception, "VM unregistration failed!" if result.exit_code != 0
      end

      @logger.info("Removed all virtual machines")
    end

    # This replaces a command with a replacement defined when this
    # isolated environment was initialized. If nothing was defined,
    # then the command itself is returned.
    def replace_command(command)
      return @apps[command] if @apps.has_key?(command)
      return command
    end
  end
end
