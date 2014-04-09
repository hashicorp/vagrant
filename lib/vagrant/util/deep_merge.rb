module Vagrant
  module Util
    module DeepMerge
      # This was lifted straight from Rails 4.0.2 as a basic Hash
      # deep merge.
      def self.deep_merge(myself, other_hash, &block)
        myself = myself.dup
        other_hash.each_pair do |k,v|
          tv = myself[k]
          if tv.is_a?(Hash) && v.is_a?(Hash)
            myself[k] = deep_merge(tv, v, &block)
          else
            myself[k] = block && tv ? block.call(k, tv, v) : v
          end
        end
        myself
      end
    end
  end
end
