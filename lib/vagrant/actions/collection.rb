module Vagrant
  module Actions
    class Collection < Array
      def dependencies!
        each_with_index do |action, i|
          action.follows.each do |klass|
            unless self[0..i].klasses.include?(klass)
              raise DependencyNotSatisfiedException.new("#{action.class} action must follow #{klass}")
            end	
          end
          
          action.precedes.each do |klass|
            unless self[i..length].klasses.include?(klass)
              raise DependencyNotSatisfiedException.new("#{action.class} action must precede #{klass}")
            end
          end
        end
      end

      def duplicates?
        klasses.uniq.size != size
      end

      def duplicates!
        raise DuplicateActionException.new if duplicates?
      end
    
      def klasses
        map { |o| o.class }
      end
    end

    class DuplicateActionException < Exception; end
    class DependencyNotSatisfiedException < Exception; end
  end
end    
