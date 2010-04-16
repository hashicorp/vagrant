module Vagrant
  module Util
    # A mixin which allows any class to be able to show a "progress meter"
    # to standard out. The progress meter shows the progress of an operation
    # with console-animated text in stdout.
    module ProgressMeter
      # Updates the progress meter with the given progress amount and total.
      # This method will do the math to figure out a percentage and show it
      # within stdout.
      #
      # @param [Float] progress Progress
      # @param [Float] total Total
      def update_progress(progress, total, show_parts=true)
        percent = (progress.to_f / total.to_f) * 100
        print "#{cl_reset}Progress: #{percent.to_i}%"
        print " (#{progress} / #{total})" if show_parts
        $stdout.flush
      end

      # Completes the progress meter by resetting it off of the screen.
      def complete_progress
        # Just clear the line back out
        print "#{cl_reset}"
      end

      def cl_reset
        reset = "\r"
        reset += "\e[0K" unless Mario::Platform.windows?
        reset
      end
    end
  end
end