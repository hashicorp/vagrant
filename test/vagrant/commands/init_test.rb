require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class CommandsInitTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Init

    @env = mock_environment
    @instance = @klass.new(@env)
  end

  context "execute" do
    should "create the vagrantfile with the first arg" do
      args = [:foo]
      @instance.expects(:create_vagrantfile).with(args.first)
      @instance.execute(args)
    end
  end

  context "creating the vagrantfile" do
    setup do
      @file = mock("file")
      @file.stubs(:write)
      File.stubs(:open).yields(@file)
      @rootfile_path = File.join(Dir.pwd, Vagrant::Environment::ROOTFILE_NAME)

      Vagrant::Util::TemplateRenderer.stubs(:render)
    end

    should "error and exit if a rootfile already exists" do
      File.expects(:exist?).with(@rootfile_path).returns(true)
      @instance.expects(:error_and_exit).with(:rootfile_already_exists).once
      @instance.create_vagrantfile
    end

    should "write to the rootfile path using the template renderer" do
      result = "foo"
      Vagrant::Util::TemplateRenderer.expects(:render).returns(result).once
      @file.expects(:write).with(result).once
      File.expects(:open).with(@rootfile_path, 'w+').yields(@file)

      @instance.create_vagrantfile
    end

    should "use the given base box if given" do
      box = "zooo"
      Vagrant::Util::TemplateRenderer.expects(:render).with(Vagrant::Environment::ROOTFILE_NAME, :default_box => box)
      @instance.create_vagrantfile(box)
    end

    should "use the default `base` if no box is given" do
      Vagrant::Util::TemplateRenderer.expects(:render).with(Vagrant::Environment::ROOTFILE_NAME, :default_box => "base")
      @instance.create_vagrantfile
    end
  end
end
