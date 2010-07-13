require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class BSDHostTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Hosts::BSD
    @env = mock_environment
    @env.stubs(:vm).returns(Vagrant::VM.new(:env => @env))
    @instance = @klass.new(@env)
  end

  context "supporting nfs check" do
    should "support NFS" do
      @instance.expects(:system).with() do |cmd|
        `which which`
        true
      end

      assert @instance.nfs?
    end

    should "not support NFS if nfsd is not found" do
      @instance.expects(:system).with() do |cmd|
        `which thisshouldnoteverneverexist`
        true
      end

      assert !@instance.nfs?
    end
  end

  context "nfs export" do
    setup do
      @instance.stubs(:system)

      @ip = "foo"
      @folders = "bar"
    end

    should "output the lines of the rendered template" do
      output = %W[foo bar baz].join("\n")
      Vagrant::Util::TemplateRenderer.expects(:render).with("nfs/exports",
                                                            :uuid => @env.vm.uuid,
                                                            :ip => @ip,
                                                            :folders => @folders).returns(output)

      @instance.expects(:system).times(output.split("\n").length)
      @instance.expects(:system).with("sudo nfsd restart")
      @instance.nfs_export(@ip, @folders)
    end
  end
end
