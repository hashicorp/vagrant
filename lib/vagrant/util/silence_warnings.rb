# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

module Vagrant
  module Util
    module SilenceWarnings
      # This silences any Ruby warnings.
      def self.silence!
        original = $VERBOSE
        $VERBOSE = nil
        return yield
      ensure
        $VERBOSE = original
      end
    end
  end
end
