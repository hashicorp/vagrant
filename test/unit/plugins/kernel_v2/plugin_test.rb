require File.expand_path("../../../base", __FILE__)


describe VagrantPlugins::Kernel_V2::Plugin do
  before do
    expect($stderr).to receive(:puts)
  end

  it "should display a warning if vagrant-alpine plugin is installed" do
  end

  context "when VAGRANT_USE_VAGRANT_ALPINE=1" do
    before do
      ENV["VAGRANT_USE_VAGRANT_ALPINE"] = "1"
    end

    it "should not display a warning" do
    end
  end
end
