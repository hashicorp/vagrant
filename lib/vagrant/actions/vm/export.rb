module Vagrant
  module Actions
    module VM
      class Export < Base
        def execute!(name=Vagrant.config.package.name, to=FileUtils.pwd)
          folder = FileUtils.mkpath(File.join(to, name))

          logger.info "Creating export directory: #{folder} ..."
          ovf_path = File.join(folder, "#{name}.ovf")

          logger.info "Exporting required VM files to directory: #{folder} ..."
          @runner.export(ovf_path)
        end
      end
    end
  end
end
