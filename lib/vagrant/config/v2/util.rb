module Vagrant
  module Config
    module V2
      class Util
        # This merges two error hashes from validate methods.
        #
        # @param [Hash] first
        # @param [Hash] second
        # @return [Hash] Merged result
        def self.merge_errors(first, second)
          first.dup.tap do |result|
            second.each do |key, value|
              result[key] ||= []
              result[key] += value
            end
          end
        end
      end
    end
  end
end
