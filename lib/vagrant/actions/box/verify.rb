module Vagrant
  module Actions
    module Box
      # This action verifies that a given box is valid. This works by attempting
      # to read/interpret the appliance file (OVF). If the reading succeeds, then
      # the box is assumed to be valid.
      class Verify < Base
        def execute!
          logger.info "Verifying box..."
          reload_configuration
          verify_appliance
        end

        def reload_configuration
          # We have to reload the environment config since we _just_ added the
          # box. We do this by setting the current box to the recently added box,
          # then reloading
          @runner.env.config.vm.box = @runner.name
          @runner.env.load_box!
          @runner.env.load_config!
        end

        def verify_appliance
          # We now try to read the applince. If it succeeds, we return true.
          VirtualBox::Appliance.new(@runner.ovf_file)
        rescue VirtualBox::Exceptions::FileErrorException
          raise ActionException.new(:box_verification_failed)
        end
      end
    end
  end
end
