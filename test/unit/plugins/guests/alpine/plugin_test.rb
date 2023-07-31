# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)


describe VagrantPlugins::GuestAlpine::Plugin do
  let(:manager) { double("manager") }

  before do
    allow(Vagrant::Plugin::Manager).to receive(:instance).and_return(manager)
  end

  context "when vagrant-alpine plugin is not installed" do
    before do
      allow(manager).to receive(:installed_plugins).and_return({})
    end

    it "should not display a warning" do
      expect($stderr).to_not receive(:puts)
      VagrantPlugins::GuestAlpine::Plugin.check_community_plugin
    end
  end

  context "when vagrant-alpine plugin is installed" do
    before do
      allow(manager).to receive(:installed_plugins).and_return({ "vagrant-alpine" => {} })
    end

    it "should display a warning" do
      expect($stderr).to receive(:puts).with(/vagrant plugin uninstall vagrant-alpine/)
      VagrantPlugins::GuestAlpine::Plugin.check_community_plugin
    end
  end
end
