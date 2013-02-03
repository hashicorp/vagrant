require "rubygems"

module VagrantPlugins
  module CommandPlugin
    module Action
      class ListPlugins
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:gem_helper].with_environment do
            specs = Gem::Specification.find_all

            specs.each do |spec|
              env[:ui].info spec.name
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
