module VagrantPlugins
  module NoopDeploy
    class Push < Vagrant.plugin("2", :push)
      def push
        @machine.communicate.tap do |comm|
          puts "pushed"
        end
      end
    end
  end
end
