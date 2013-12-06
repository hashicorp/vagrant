require 'set'

module VagrantPlugins
  module Docker
    class Config < Vagrant.plugin("2", :config)
      attr_reader :images, :containers
      attr_accessor :version

      def initialize
        @images     = Set.new
        @containers = Hash.new
        @version    = UNSET_VALUE
      end

      def images=(images)
        @images = Set.new(images)
      end

      def pull_images(*images)
        @images += images.map(&:to_s)
      end

      def run(name, **options)
        params = options.dup
        params[:image] ||= name

        # TODO: Validate provided parameters before assignment
        @containers[name.to_s] = params
      end

      def finalize!
        @version = "latest" if @version == UNSET_VALUE
        @version = @version.to_sym
      end

      def merge(other)
        super.tap do |result|
          result.pull_images(*(other.images + self.images))
        end
      end
    end
  end
end
