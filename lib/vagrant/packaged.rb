module Vagrant
  class Packaged
    attr_reader :vm, :file, :name

    def initialize(name, params)
      @vm = params[:vm]
      @file = params[:file]
      @name = name
    end

    def compressed?
      @file
    end
    
    def decompress(to)
      # move folder unless compressed?
      # decompress
      # return File object of ovf for import
    end
    
    def compress(to)
      folder = FileUtils.mkpath(File.join(to, @name))
      
      return @file if compressed?

      ovf_path = File.join(folder, "#{@name}.ovf")
      tar_path = "#{folder}.tar"
      
      @vm.export(ovf_path)
      
      # TODO use zlib ...
      Tar.open(tar_path, File::CREAT | File::WRONLY, 0644, Tar::GNU) do |tar|
        begin
          working_dir = FileUtils.pwd
          FileUtils.cd(to)
          tar.append_tree(@name)
        ensure
          FileUtils.cd(working_dir)

        end
      end

      # TODO remove directory
      

      tar_path
    end
    
    def ovf; "#{@name}.ovf" end
  end
end
