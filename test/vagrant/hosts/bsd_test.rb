require "test_helper"

class BSDHostTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Hosts::BSD
    @env = vagrant_env
    @instance = @klass.new(@env.vms.values.first.env)
  end

  context "supporting nfs check" do
    should "support NFS" do
      result = @instance.sh("echo")
      @instance.expects(:sh).returns(result)
      assert @instance.nfs?
    end

    should "not support NFS if nfsd is not found" do
      result = @instance.sh("sdalkfjasdlkfj")
      @instance.expects(:sh).returns(result)
      assert !@instance.nfs?
    end

    should "retry until a boolean is returned" do
      result = @instance.sh("echo")

      seq = sequence("seq")
      @instance.expects(:sh).once.in_sequence(seq).raises(TypeError.new("foo"))
      @instance.expects(:sh).once.in_sequence(seq).returns(result)
      assert @instance.nfs?
    end
  end

  context "nfs export" do
    setup do
      @instance.stubs(:sh)

      @ip = "foo"
      @folders = "bar"
    end

    should "output the lines of the rendered template" do
      output = %W[foo bar baz].join("\n")
      Vagrant::Util::TemplateRenderer.expects(:render).with("nfs/exports",
                                                            :uuid => @instance.env.vm.uuid,
                                                            :ip => @ip,
                                                            :folders => @folders).returns(output)

      @instance.expects(:sh).times(output.split("\n").length)
      @instance.expects(:sh).with("sudo nfsd restart")
      @instance.nfs_export(@ip, @folders)
    end
  end

  context "nfs cleanup" do
    # TODO: How to test all the system calls?
  end
end
