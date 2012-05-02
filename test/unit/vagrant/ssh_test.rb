require File.expand_path("../../base", __FILE__)

describe Vagrant::SSH do
  context "check_key_permissions" do
    let(:key_path) do
      # We create a tempfile to guarantee some level of uniqueness
      # then explicitly close/unlink but save the path so we can re-use
      temp = Tempfile.new("vagrant")
      result = Pathname.new(temp.path)
      temp.close
      temp.unlink

      result
    end

    let(:ssh_instance) { Vagrant::SSH.new(double) }

    before(:each) do
      key_path.open("w") do |f|
        f.write("hello!")
      end

      key_path.chmod(0644)
    end

    it "should not raise an exception if we set a keyfile permission correctly" do
      ssh_instance.check_key_permissions(key_path)
    end
  end
end

