require 'fileutils'

module VagrantTestHelpers
  module Environment
    # Creates a "vagrant_app" directory in the test tmp folder
    # which can be used for creating test Vagrant environments.
    # Returns the root directory of the app.
    def vagrant_app(*path)
      root = tmp_path.join("vagrant_app")
      FileUtils.rm_rf(root)
      FileUtils.mkdir_p(root)
      root.join(*path)
    end

    # Creates a Vagrantfile with the given contents in the given
    # app directory.
    def vagrantfile(*args)
      path = args.shift.join("Vagrantfile") if Pathname === args.first
      path ||= vagrant_app("Vagrantfile")
      str  = args.shift || ""
      File.open(path.to_s, "w") do |f|
        f.puts "Vagrant::Config.run do |config|"
        f.puts "config.vagrant.log_output = nil"
        f.puts "config.vagrant.home = '#{home_path}'"
        f.puts str
        f.puts "end"
      end

      path.parent
    end

    # Creates and _loads_ a Vagrant environment at the given path
    def vagrant_env(*args)
      path = args.shift if Pathname === args.first
      path ||= vagrantfile
      Vagrant::Environment.new(:cwd => path).load!
    end

    # Creates the folder to contain a vagrant box
    def vagrant_box(name)
      result = boxes_path.join(name)
      FileUtils.mkdir_p(result)
      result
    end
  end
end
