require 'optparse'

module VagrantPlugins
  module CommandGlobalStatus
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "outputs status Vagrant environments for this user"
      end

      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant global-status"
          o.separator ""
          o.on("--prune", "Prune invalid entries.") do |p|
            options[:prune] = true
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        columns = [
          ["id", :id],
          ["name", :name],
          ["provider", :provider],
          ["state", :state],
          ["directory", :vagrantfile_path],
        ]

        widths = {}
        widths[:id] = 8
        widths[:name] = 6
        widths[:provider] = 6
        widths[:state] = 6
        widths[:vagrantfile_path] = 35

        entries = []
        prune   = []
        @env.machine_index.each do |entry|
          # If we're pruning and this entry is invalid, skip it
          # and prune it later.
          if options[:prune] && !entry.valid?(@env.home_path)
            prune << entry
            next
          end

          entries << entry

          columns.each do |_, method|
            # Skip the id
            next if method == :id

            widths[method] ||= 0
            cur = entry.send(method).to_s.length
            widths[method] = cur if cur > widths[method]
          end
        end

        # Prune all the entries to prune
        prune.each do |entry|
          deletable = @env.machine_index.get(entry.id)
          @env.machine_index.delete(deletable) if deletable
        end

        total_width = 0
        columns.each do |header, method|
          header = header.ljust(widths[method]) if widths[method]
          @env.ui.info("#{header} ", new_line: false)
          total_width += header.length + 1
        end
        @env.ui.info("")
        @env.ui.info("-" * total_width)

        if entries.empty?
          @env.ui.info(I18n.t("vagrant.global_status_none"))
          return 0
        end

        entries.each do |entry|
          columns.each do |_, method|
            v = entry.send(method).to_s
            v = v[0...7] if method == :id
            v = v.ljust(widths[method]) if widths[method]
            @env.ui.info("#{v} ", new_line: false)
          end

          @env.ui.info("")
        end

        @env.ui.info(" \n" + I18n.t("vagrant.global_status_footer"))

        # Success, exit status 0
        0
      end
    end
  end
end
