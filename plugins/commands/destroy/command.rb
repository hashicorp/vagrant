module VagrantPlugins
  module CommandDestroy
    class Command < Vagrant.plugin("2", :command)
      def execute
        options = {}
        options[:force] = false

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant destroy [vm-name]"
          o.separator ""

          o.on("-f", "--force", "Destroy without confirmation.") do |f|
            options[:force] = f
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("'Destroy' each target VM...")
        with_target_vms(argv, :reverse => true) do |vm|
          vm.action(:destroy, :force_confirm_destroy => options[:force])
        end

        # Success, exit status 0
        0
      end
    end
  end
end
