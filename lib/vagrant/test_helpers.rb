module Vagrant
  # Test helpers provided by Vagrant to allow for plugin developers
  # to write automated tests for their code. This module simply provides
  # methods which can be included into any test framework (`test/unit`,
  # RSpec, Shoulda, etc.)
  module TestHelpers
    #------------------------------------------------------------
    # Environment creation helpers
    #------------------------------------------------------------
    # Creates a "vagrant_app" directory in the test tmp folder
    # which can be used for creating test Vagrant environments.
    # Returns the root directory of the app. This typically doesn't need
    # to be called directly unless you're setting up a custom application.
    # See the examples for common use cases.
    def vagrant_app(*path)
      root = tmp_path.join("vagrant_app")
      FileUtils.rm_rf(root)
      FileUtils.mkdir_p(root)
      root.join(*path)
    end

    # Creates a Vagrantfile with the given contents in the given
    # app directory. If no app directory is specified, then a default
    # Vagrant app is used.
    def vagrantfile(*args)
      path = args.shift.join("Vagrantfile") if Pathname === args.first
      path ||= vagrant_app("Vagrantfile")

      # Create this box so that it exists
      vagrant_box("base")

      str  = args.shift || ""
      File.open(path.to_s, "w") do |f|
        f.puts "ENV['VAGRANT_HOME'] = '#{home_path}'"
        f.puts "Vagrant::Config.run do |config|"
        f.puts "config.vm.base_mac = 'foo' if !config.vm.base_mac"
        f.puts "config.vm.box = 'base'"
        f.puts str
        f.puts "end"
      end

      path.parent
    end

    # Creates and _loads_ a Vagrant environment at the given path.
    # If no path is given, then a default {#vagrantfile} is used.
    def vagrant_env(*args)
      path = args.shift if Pathname === args.first
      path ||= vagrantfile
      Vagrant::Environment.new(:cwd => path).load!
    end

    # Creates the folder to contain a vagrant box. This allows for
    # "fake" boxes to be made with the specified name.
    #
    # @param [String] name
    # @return [Pathname]
    def vagrant_box(name)
      result = boxes_path.join(name)
      FileUtils.mkdir_p(result)
      result
    end

    # Returns an instantiated downloader with a mocked tempfile
    # which can be passed into it.
    #
    # @param [Class] klass The downloader class
    # @return [Array] Returns an array of `downloader` `tempfile`
    def vagrant_mock_downloader(klass)
      tempfile = mock("tempfile")
      tempfile.stubs(:write)

      _, env = action_env
      [klass.new(env), tempfile]
    end

    # Returns a blank app (callable) and action environment with the
    # given vagrant environment. This allows for testing of middlewares.
    def action_env(v_env = nil)
      v_env ||= vagrant_env
      # duplicate the Vagrant::Environment ui and get the default vm object
      # for the new action environment from the first pair in the vms list
      opts = {:ui => v_env.ui.dup, :vm => v_env.vms.first.last}
      app = lambda { |env| }
      env = Vagrant::Action::Environment.new(opts)
      env["vagrant.test"] = true
      [app, env]
    end

    # Utility method for capturing output streams.
    # @example Evaluate the output
    #   output = capture(:stdout){ env.cli("foo") }
    #   assert_equal "bar", output
    # @example Silence the output
    #   silence(:stdout){ env.cli("init") }
    # @param [:stdout, :stderr] stream The stream to capture
    # @yieldreturn String
    # @see https://github.com/wycats/thor/blob/master/spec/spec_helper.rb
    def capture(stream)
      begin
        stream = stream.to_s
        eval "$#{stream} = StringIO.new"
        yield
        result = eval("$#{stream}").string
      ensure
        eval("$#{stream} = #{stream.upcase}")
      end

      result
    end
    alias :silence :capture

    #------------------------------------------------------------
    # Path helpers
    #------------------------------------------------------------
    # Path to the tmp directory for the tests.
    #
    # @return [Pathname]
    def tmp_path
      result = Vagrant.source_root.join("test", "tmp")
      FileUtils.mkdir_p(result)
      result
    end

    # Path to the "home" directory for the tests
    #
    # @return [Pathname]
    def home_path
      result = tmp_path.join("home")
      FileUtils.mkdir_p(result)
      result
    end

    # Path to the boxes directory in the home directory
    #
    # @return [Pathname]
    def boxes_path
      result = home_path.join("boxes")
      FileUtils.mkdir_p(result)
      result
    end

    # Cleans all the test temp paths, which includes the boxes path,
    # home path, etc. This allows for cleaning between tests.
    def clean_paths
      FileUtils.rm_rf(tmp_path)

      # Call these methods only to rebuild the directories
      tmp_path
      home_path
      boxes_path
    end
  end
end
