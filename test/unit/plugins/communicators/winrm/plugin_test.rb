# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/communicators/winrm/plugin")

describe VagrantPlugins::CommunicatorWinRM::Plugin do
  describe "#init!" do
    let(:manager_instance) { double("manager_instance", installed_plugins: installed_plugins) }
    let(:installed_plugins) { {} }

    before do
      allow(I18n).to receive(:load_path).and_return("")
      allow(I18n).to receive(:reload!)
      allow(described_class).to receive(:require)
      allow(Vagrant::Plugin::Manager).to receive(:instance).and_return(manager_instance)
    end

    after do
      described_class.init!
      described_class.reset!
    end

    it "should not output any warning" do
      expect($stderr).not_to receive(:puts).with(/WARNING/)
    end

    context "when vagrant-winrm plugin is installed" do
      let(:installed_plugins) { {"vagrant-winrm" => "PLUGIN_INFO"} }

      it "should output a warning" do
        expect($stderr).to receive(:puts).with(/WARNING/)
      end

      context "with VAGRANT_IGNORE_WINRM_PLUGIN set" do
        before { allow(ENV).to receive(:[]).with("VAGRANT_IGNORE_WINRM_PLUGIN").and_return("1") }

        it "should not output any warning" do
          expect($stderr).not_to receive(:puts).with(/WARNING/)
        end
      end
    end
  end
end
