require 'json'

module VagrantPlugins
  module Salt
    class Provisioner < Vagrant.plugin("2", :provisioner)

      # Default path values to set within configuration only
      # if configuration value is unset and local path exists
      OPTIMISTIC_PATH_DEFAULTS = Hash[*[
        "minion_config", "salt/minion",
        "minion_key", "salt/key/minion.key",
        "minion_pub", "salt/key/minion.pub",
        "master_config", "salt/master",
        "master_key", "salt/key/master.key",
        "master_pub", "salt/key/master.pub"
      ].map(&:freeze)].freeze

      def provision
        set_default_configs
        upload_configs
        upload_keys
        run_bootstrap_script
        call_overstate
        call_highstate
        call_orchestrate
      end

      # Return a list of accepted keys
      def keys(group='minions')
        out = @machine.communicate.sudo("salt-key --out json") do |type, output|
          begin
            if type == :stdout
              out = JSON::load(output)
              break out[group]
            end
          end
        end
        return out
      end

      ## Utilities
      def expanded_path(rel_path)
        Pathname.new(rel_path).expand_path(@machine.env.root_path)
      end

      def binaries_found
        ## Determine States, ie: install vs configure
        desired_binaries = []
        if !@config.no_minion
          if @machine.config.vm.communicator == :winrm
            desired_binaries.push('C:\\salt\\salt-minion.bat')
            desired_binaries.push('C:\\salt\\salt-call.bat')
          else
            desired_binaries.push('salt-minion')
            desired_binaries.push('salt-call')
          end
        end

        if @config.install_master
          if @machine.config.vm.communicator == :winrm
            raise Vagrant::Errors::ProvisionerWinRMUnsupported,
              name: "salt.install_master"
          else
            desired_binaries.push('salt-master')
          end
        end

        if @config.install_syndic
          if @machine.config.vm.communicator == :winrm
            raise Vagrant::Errors::ProvisionerWinRMUnsupported,
              name: "salt.install_syndic"
          else
            desired_binaries.push('salt-syndic')
          end
        end

        found = true
        for binary in desired_binaries
          @machine.env.ui.info "Checking if %s is installed" % binary
          if !@machine.communicate.test("which %s" % binary)
            @machine.env.ui.info "%s was not found." % binary
            found = false
          else
            @machine.env.ui.info "%s found" % binary
          end
        end

        return found
      end

      def need_configure
        @config.minion_config or @config.minion_key or @config.master_config or @config.master_key or @config.grains_config or @config.version
      end

      def need_install
        if @config.always_install
          return true
        else
          return !binaries_found()
        end
      end

      def temp_config_dir
        if @machine.config.vm.communicator == :winrm
          return @config.temp_config_dir || "C:\\tmp"
        else
          return @config.temp_config_dir || "/tmp"
        end
      end

      # Generates option string for bootstrap script
      def bootstrap_options(install, configure, config_dir)
        options = ""

        # Any extra options passed to bootstrap
        if @config.bootstrap_options
          options = "%s %s" % [options, @config.bootstrap_options]
        end

        if configure && @machine.config.vm.communicator != :winrm
          options = "%s -F -c %s" % [options, config_dir]
        end

        if @config.seed_master && @config.install_master
          seed_dir = "/tmp/minion-seed-keys"
          @machine.communicate.sudo("mkdir -p -m777 #{seed_dir}")
          @config.seed_master.each do |name, keyfile|
            sourcepath = expanded_path(keyfile).to_s
            dest = "#{seed_dir}/#{name}"
            @machine.communicate.upload(sourcepath, dest)
          end
          options = "#{options} -k #{seed_dir}"
        end

        if configure && !install
          options = "%s -C" % options
        end

        if @config.install_master
          options = "%s -M" % options
        end

        if @config.install_syndic
          options = "%s -S" % options
        end

        if @config.no_minion
          options = "%s -N" % options
        end

        if @config.install_type
          options = "%s %s" % [options, @config.install_type]
        end

        if @config.install_args
          options = "%s %s" % [options, @config.install_args]
        end

        if @config.verbose
          @machine.env.ui.info "Using Bootstrap Options: %s" % options
        end

        return options
      end

      ## Actions
      # Get pillar string to pass with the salt command
      def get_pillar
        " pillar='#{@config.pillar_data.to_json}'" if !@config.pillar_data.empty?
      end

      # Get colorization option string to pass with the salt command
      def get_colorize
        @config.colorize ? " --force-color" : " --no-color"
      end

      # Get log output level option string to pass with the salt command
      def get_loglevel
        log_levels = ["all", "garbage", "trace", "debug", "info", "warning", "error", "quiet"]
        if log_levels.include? @config.log_level
          " --log-level=#{@config.log_level}"
        else
          " --log-level=debug"
        end
      end

      # Copy master and minion configs to VM
      def upload_configs
        if @config.minion_config
          @machine.env.ui.info "Copying salt minion config to vm."
          @machine.communicate.upload(expanded_path(@config.minion_config).to_s, temp_config_dir + "/minion")
        end

        if @config.master_config
          @machine.env.ui.info "Copying salt master config to vm."
          @machine.communicate.upload(expanded_path(@config.master_config).to_s, temp_config_dir + "/master")
        end

        if @config.grains_config
          @machine.env.ui.info "Copying salt grains config to vm."
          @machine.communicate.upload(expanded_path(@config.grains_config).to_s, temp_config_dir + "/grains")
        end
      end

      # Copy master and minion keys to VM
      def upload_keys
        if @config.minion_key and @config.minion_pub
          @machine.env.ui.info "Uploading minion keys."
          @machine.communicate.upload(expanded_path(@config.minion_key).to_s, temp_config_dir + "/minion.pem")
          @machine.communicate.sudo("chmod u+w #{temp_config_dir}/minion.pem")
          @machine.communicate.upload(expanded_path(@config.minion_pub).to_s, temp_config_dir + "/minion.pub")
        end

        if @config.master_key and @config.master_pub
          @machine.env.ui.info "Uploading master keys."
          @machine.communicate.upload(expanded_path(@config.master_key).to_s, temp_config_dir + "/master.pem")
          @machine.communicate.sudo("chmod u+w #{temp_config_dir}/master.pem")
          @machine.communicate.upload(expanded_path(@config.master_pub).to_s, temp_config_dir + "/master.pub")
        end
      end

      # Get bootstrap file location, bundled or custom
      def get_bootstrap
        if @config.bootstrap_script
          bootstrap_abs_path = expanded_path(@config.bootstrap_script)
        else
          if @machine.config.vm.communicator == :winrm
            bootstrap_abs_path = Pathname.new("../bootstrap-salt.ps1").expand_path(__FILE__)
          else
            bootstrap_abs_path = Pathname.new("../bootstrap-salt.sh").expand_path(__FILE__)
          end
        end

        return bootstrap_abs_path
      end

      # Determine if we are configure and/or installing, then do either
      def run_bootstrap_script
        install = need_install()
        configure = need_configure()
        config_dir = temp_config_dir()
        options = bootstrap_options(install, configure, config_dir)

        if configure or install
          if configure and !install
            @machine.env.ui.info "Salt binaries found. Configuring only."
          else
            @machine.env.ui.info "Bootstrapping Salt... (this may take a while)"
          end

          bootstrap_path = get_bootstrap
          if @machine.config.vm.communicator == :winrm
            if @config.version
              options += " -version %s" % @config.version
            end
            if @config.run_service
              @machine.env.ui.info "Salt minion will be stopped after installing."
              options += " -runservice %s" % @config.run_service
            end
            if @config.minion_id
              @machine.env.ui.info "Setting minion to @config.minion_id."
              options += " -minion %s" % @config.minion_id
            end
            if @config.master_id
              @machine.env.ui.info "Setting master to @config.master_id."
              options += " -master %s" % @config.master_id
            end
            bootstrap_destination = File.join(config_dir, "bootstrap_salt.ps1")
          else
            bootstrap_destination = File.join(config_dir, "bootstrap_salt.sh")
          end

          if @machine.communicate.test("test -f %s" % bootstrap_destination)
            @machine.communicate.sudo("rm -f %s" % bootstrap_destination)
          end
          @machine.communicate.upload(bootstrap_path.to_s, bootstrap_destination)
          @machine.communicate.sudo("chmod +x %s" % bootstrap_destination)
          if @machine.config.vm.communicator == :winrm
            bootstrap = @machine.communicate.sudo("powershell.exe -executionpolicy bypass -file %s %s" % [bootstrap_destination, options]) do |type, data|
              if data[0] == "\n"
                # Remove any leading newline but not whitespace. If we wanted to
                # remove newlines and whitespace we would have used data.lstrip
                data = data[1..-1]
              end
              if @config.verbose
                @machine.env.ui.info(data.rstrip)
              end
            end
          else
            bootstrap = @machine.communicate.sudo("%s %s" % [bootstrap_destination, options]) do |type, data|
              if data[0] == "\n"
                # Remove any leading newline but not whitespace. If we wanted to
                # remove newlines and whitespace we would have used data.lstrip
                data = data[1..-1]
              end
              if @config.verbose
                @machine.env.ui.info(data.rstrip)
              end
            end
          end

          if !bootstrap
            raise Salt::Errors::SaltError, :bootstrap_failed
          end

          if configure and !install
            @machine.env.ui.info "Salt successfully configured!"
          elsif configure and install
            @machine.env.ui.info "Salt successfully configured and installed!"
          elsif !configure and install
            @machine.env.ui.info "Salt successfully installed!"
          end
        else
          @machine.env.ui.info "Salt did not need installing or configuring."
        end
      end

      def call_overstate
        if @config.run_overstate
          if @config.install_master
            @machine.env.ui.info "Calling state.overstate... (this may take a while)"
            @machine.communicate.sudo("salt '*' saltutil.sync_all")
            @machine.communicate.sudo("salt-run state.over") do |type, data|
              if @config.verbose
                @machine.env.ui.info(data)
              end
            end
          else
            @machine.env.ui.info "run_overstate does not make sense on a minion. Not running state.overstate."
          end
        else
          @machine.env.ui.info "run_overstate set to false. Not running state.overstate."
        end
      end

      def call_highstate
        if @config.run_highstate
          local=""
          if @config.masterless
            local=" --local"
          end
          @machine.env.ui.info "Calling state.highstate... (this may take a while)"
          if @config.install_master
            unless @config.masterless?
              @machine.communicate.sudo("salt '*' saltutil.sync_all")
            end
            @machine.communicate.sudo("salt '*' state.highstate --verbose #{local}#{get_loglevel}#{get_colorize}#{get_pillar}") do |type, data|
            if @config.verbose
                @machine.env.ui.info(data.rstrip)
            end
          end
          else
            if @machine.config.vm.communicator == :winrm
              opts = { elevated: true }
              unless @config.masterless?
                @machine.communicate.execute("C:\\salt\\salt-call.bat saltutil.sync_all", opts)
              end
              @machine.communicate.execute("C:\\salt\\salt-call.bat state.highstate --retcode-passthrough #{local}#{get_loglevel}#{get_colorize}#{get_pillar}", opts) do |type, data|
                if @config.verbose
                  @machine.env.ui.info(data.rstrip)
                end
              end
            else
              unless @config.masterless?
                @machine.communicate.sudo("salt-call saltutil.sync_all")
              end
              @machine.communicate.sudo("salt-call state.highstate --retcode-passthrough #{local}#{get_loglevel}#{get_colorize}#{get_pillar}") do |type, data|
                if @config.verbose
                  @machine.env.ui.info(data.rstrip)
                end
              end
            end
          end
        else
          @machine.env.ui.info "run_highstate set to false. Not running state.highstate."
        end
      end

      def call_orchestrate
        if !@config.orchestrations
          @machine.env.ui.info "orchestrate is nil. Not running state.orchestrate."
          return
        end

        if !@config.install_master
          @machine.env.ui.info "orchestrate does not make sense on a minion. Not running state.orchestrate."
          return
        end

        log_output = lambda do |type, data|
          if @config.verbose
            @machine.env.ui.info(data)
          end
        end

        @machine.env.ui.info "Running the following orchestrations: #{@config.orchestrations}"
        @machine.env.ui.info "Running saltutil.sync_all before orchestrating"
        @machine.communicate.sudo("salt '*' saltutil.sync_all", &log_output)

        @config.orchestrations.each do |orchestration|
          cmd = "salt-run -l info state.orchestrate #{orchestration}"
          @machine.env.ui.info "Calling #{cmd}... (this may take a while)"
          @machine.communicate.sudo(cmd, &log_output)
        end
      end

      # Sets optimistic default values into config
      def set_default_configs
        OPTIMISTIC_PATH_DEFAULTS.each do |config_key, config_default|
          if config.send(config_key) == Config::UNSET_VALUE
            config_value = File.exist?(expanded_path(config_default)) ? config_default : nil
            config.send("#{config_key}=", config_value)
          end
        end
      end
    end
  end
end
