module Vagrant
  module Action
    module VM
      # This class allows other actions on the virtual machine object
      # to be consolidated under a single write lock. This vastly speeds
      # up modification of virtual machines. This should be used whereever
      # possible when dealing with virtual machine modifications.
      class Modify
        include Util::StackedProcRunner

        def initialize(app, env)
          @app = app

          # Initialize the proc_stack, which should already be empty
          # but just making sure here.
          proc_stack.clear

          # Create the lambda in the environment which is to be called
          # to add new procs to the modification sequence.
          env["vm.modify"] = lambda do |*procs|
            procs.each { |p| push_proc(&p) }
          end
        end

        def call(env)
          # Run the procs we have saved up, save the machine, and reload
          # to verify we get the new settings
          run_procs!(env[:vm].vm)
          env[:vm].vm.save
          env[:vm].reload!

          @app.call(env)
        end
      end
    end
  end
end
