require 'set'

module VagrantPlugins
  module Docker
    class Config < Vagrant.plugin("2", :config)
      attr_reader :images, :containers
      attr_accessor :version

      def initialize
        @images     = Set.new
        @containers = Hash.new
        @version    = :latest
      end

      def images=(images)
        @images = Set.new(images)
      end

      def pull_images(*images)
        @images += images.map(&:to_s)
      end

      def run(*args)
        container_name = args.shift
        params         = {}

        if args.empty?
          params[:image] = container_name
        elsif args.first.is_a?(String)
          params[:image] = args.shift
          params[:cmd]   = container_name
        else
          params = args.shift
          params[:cmd] ||= container_name
        end

        # TODO: Validate provided parameters before assignment
        @containers[container_name.to_s] = params
      end

      def finalize!
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
