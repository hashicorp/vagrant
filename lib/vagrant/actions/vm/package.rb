module Vagrant
  module Actions
    module VM
      class Package < Base
        attr_accessor :out_path
        attr_accessor :include_files
        attr_reader :export_action

        def initialize(vm, out_path = nil, include_files = nil, *args)
          super
          @out_path = out_path || "package"
          @include_files = include_files || []
          @temp_path = nil
        end

        def prepare
          # Verify the existance of all the additional files, if any
          @include_files.each do |file|
            raise ActionException.new(:package_include_file_doesnt_exist, :filename => file) unless File.exists?(file)
          end

          # Get the export action and store a reference to it
          @export_action = @runner.find_action(Export)
          raise ActionException.new(:packaged_requires_export) unless @export_action
        end

        def execute!
          compress
        end

        def tar_path
          File.join(FileUtils.pwd, "#{out_path}#{@runner.env.config.package.extension}")
        end

        def temp_path
          export_action.temp_dir
        end

        # This method copies the include files (passed in via command line)
        # to the temporary directory so they are included in a sub-folder within
        # the actual box
        def copy_include_files
          if include_files.length > 0
            include_dir = File.join(temp_path, "include")
            FileUtils.mkdir_p(include_dir)

            include_files.each do |f|
              logger.info "Packaging additional file: #{f}"
              FileUtils.cp(f, include_dir)
            end
          end
        end

        # This method creates the auto-generated Vagrantfile at the root of the
        # box. This Vagrantfile contains the MAC address so that the user doesn't
        # have to worry about it.
        def create_vagrantfile
          File.open(File.join(temp_path, "Vagrantfile"), "w") do |f|
            f.write(TemplateRenderer.render("package_Vagrantfile", {
              :base_mac => @runner.vm.network_adapters.first.mac_address
            }))
          end
        end

        def compress
          logger.info "Packaging VM into #{tar_path}..."
          File.open(tar_path, File::CREAT | File::WRONLY, 0644) do |tar|
            Archive::Tar::Minitar::Output.open(tar) do |output|
              begin
                current_dir = FileUtils.pwd

                copy_include_files
                create_vagrantfile

                FileUtils.cd(temp_path)
                Dir.glob(File.join(".", "**", "*")).each do |entry|
                  Archive::Tar::Minitar.pack_file(entry, output)
                end
              ensure
                FileUtils.cd(current_dir)
              end
            end
          end
        end
      end
    end
  end
end
