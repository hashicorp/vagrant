require 'fileutils'

module Vagrant
  module Command
    class UpgradeTo060Command < Base
      register "upgrade_to_060", "Upgrade pre-0.6.0 environment to 0.6.0", :hide => true

      def execute
        @env.ui.warn I18n.t("vagrant.commands.upgrade_to_060.info"), :prefix => false
        @env.ui.warn "", :prefix => false
        if !@env.ui.yes? I18n.t("vagrant.commands.upgrade_to_060.ask"), :prefix => false, :color => :yellow
          @env.ui.info I18n.t("vagrant.commands.upgrade_to_060.quit"), :prefix => false
          return
        end

        local_data = @env.local_data
        if !local_data.empty?
          if local_data[:active]
            @env.ui.confirm I18n.t("vagrant.commands.upgrade_to_060.already_done"), :prefix => false
            return
          end

          # Backup the previous file
          @env.ui.info I18n.t("vagrant.commands.upgrade_to_060.backing_up"), :prefix => false
          FileUtils.cp(local_data.file_path, "#{local_data.file_path}.bak-#{Time.now.to_i}")

          # Gather the previously set virtual machines into a single
          # active hash
          active = local_data.inject({}) do |acc, data|
            key, uuid = data
            acc[key.to_sym] = uuid
            acc
          end

          # Set the active hash to the active list and save it
          local_data.clear
          local_data[:active] = active
          local_data.commit
        end

        @env.ui.confirm I18n.t("vagrant.commands.upgrade_to_060.complete"), :prefix => false
      end
    end
  end
end
