module VagrantPlugins
  module FileUpload
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def provision
        @machine.communicate.tap do |comm|
          # Make sure the remote path exists
          command = "mkdir -p %s" % File.dirname(config.destination)
          comm.execute(command) 

          # now upload the file
          comm.upload(File.expand_path(config.source), config.destination)
        end
      end
    end
  end
end
