module Vagrant
  module Command
    class VersionCommand < Base
      desc "Prints the Vagrant version information"
      register "version", :alias => %w(-v --version)

      def version
        env.ui.info "Vagrant version #{Vagrant::VERSION}"
      end
    end
  end
end
