require File.expand_path("../../base", __FILE__)

describe Vagrant::SSH do
  context "check_key_permissions" do
    let(:key_path) { File.expand_path("../id_rsa", __FILE__) }
    let(:ssh_instance) { Vagrant::SSH.new(double) }

    before(:each) do
      File.open(key_path, 'w') do |file|
        file.write("hello!")
      end
      File.chmod(644, key_path)
    end

    after(:each) do
      FileUtils.rm(key_path)
    end

    it "should not raise an exception if we set a keyfile permission correctly" do
      ssh_instance.check_key_permissions(key_path)
    end
    
  end
end

