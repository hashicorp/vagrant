require "log4r"
require "singleton"

module Vagrant
  module Util
    class CheckpointClient

      include Singleton

      # Maximum number of seconds to wait for check to complete
      CHECKPOINT_TIMEOUT = 10

      # @return [Log4r::Logger]
      attr_reader :logger

      # @return [Boolean]
      attr_reader :enabled

      # @return [Hash]
      attr_reader :files

      # @return [Vagrant::Environment]
      attr_reader :env

      def initialize
        @logger = Log4r::Logger.new("vagrant::checkpoint_client")
        @enabled = false
      end

      # Setup will attempt to load the checkpoint library and define
      # required paths
      #
      # @param [Vagrant::Environment] env
      # @return [self]
      def setup(env)
        begin
          require "checkpoint"
          @enabled = true
        rescue LoadError
          @logger.warn("checkpoint library not found. disabling.")
        end
        if ENV["VAGRANT_CHECKPOINT_DISABLE"]
          @logger.debug("checkpoint disabled via explicit user request")
          @enabled = false
        end
        @files = {
          signature: env.data_dir.join("checkpoint_signature"),
          cache: env.data_dir.join("checkpoint_cache")
        }
        @checkpoint_thread = nil
        @env = env
        self
      end

      # Check has completed
      def complete?
        !@checkpoint_thread.nil? && !@checkpoint_thread.alive?
      end

      # Result of check
      #
      # @return [Hash, nil]
      def result
        if !enabled || @checkpoint_thread.nil?
          nil
        elsif !defined?(@result)
          @checkpoint_thread.join(CHECKPOINT_TIMEOUT)
          @result = @checkpoint_thread[:result]
        else
          @result
        end
      end

      # Run check
      #
      # @return [self]
      def check
        if enabled && @checkpoint_thread.nil?
          logger.debug("starting plugin check")
          @checkpoint_thread = Thread.new do
            Thread.current.abort_on_exception = false
            if Thread.current.respond_to?(:report_on_exception=)
              Thread.current.report_on_exception = false
            end
            begin
              Thread.current[:result] = Checkpoint.check(
                product: "vagrant",
                version: VERSION,
                signature_file: files[:signature],
                cache_file: files[:cache]
              )
              if !Thread.current[:result].is_a?(Hash)
                Thread.current[:result] = nil
              end
              logger.debug("plugin check complete")
            rescue => e
              logger.debug("plugin check failure - #{e}")
            end
          end
        end
        self
      end

      # Display any alerts or version update information
      #
      # @return [boolean] true if displayed, false if not
      def display
        if !defined?(@displayed)
          if !complete?
            @logger.debug("waiting for checkpoint to complete...")
          end
          # Don't display if information is cached
          if result && !result["cached"]
            version_check
            alerts_check
          else
            @logger.debug("no information received from checkpoint")
          end
          @displayed = true
        else
          false
        end
      end

      def alerts_check
        if result["alerts"] && !result["alerts"].empty?
          result["alerts"].group_by{|a| a["level"]}.each_pair do |_, alerts|
            alerts.each do |alert|
              date = nil
              begin
                date = Time.at(alert["date"])
              rescue
                date = Time.now
              end
              output = I18n.t("vagrant.alert",
                message: alert["message"],
                date: date,
                url: alert["url"]
              )
              case alert["level"]
              when "info"
                alert_ui = Vagrant::UI::Prefixed.new(env.ui, "vagrant")
                alert_ui.info(output)
              when "warn"
                alert_ui = Vagrant::UI::Prefixed.new(env.ui, "vagrant-warning")
                alert_ui.warn(output)
              when "critical"
                alert_ui = Vagrant::UI::Prefixed.new(env.ui, "vagrant-alert")
                alert_ui.error(output)
              end
            end
            env.ui.info("")
          end
        else
          @logger.debug("no alert notifications to display")
        end
      end

      def version_check
        latest_version = Gem::Version.new(result["current_version"])
        installed_version = Gem::Version.new(VERSION)
        ui = Vagrant::UI::Prefixed.new(env.ui, "vagrant")
        if latest_version > installed_version
          @logger.info("new version of Vagrant available - #{latest_version}")
          ui.info(I18n.t("vagrant.version_upgrade_available", latest_version: latest_version, installed_version: installed_version), channel: :error)
          env.ui.info("", channel: :error)
        else
          @logger.debug("vagrant is currently up to date")
        end
      end

      # @private
      # Reset the cached values for platform. This is not considered a public
      # API and should only be used for testing.
      def reset!
        logger = @logger
        instance_variables.each(&method(:remove_instance_variable))
        @logger = logger
        @enabled = false
      end
    end
  end
end
