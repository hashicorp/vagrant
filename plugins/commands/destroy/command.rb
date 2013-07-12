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
        declined = false
        with_target_vms(argv, :reverse => true) do |vm|
          action_env = vm.action(
            :destroy, :force_confirm_destroy => options[:force])

          declined = true if action_env.has_key?(:force_confirm_destroy_result) &&
            action_env[:force_confirm_destroy_result] == false
        end

        # Success if no confirms were declined
        declined ? 1 : 0
      end
    end
  end
end
