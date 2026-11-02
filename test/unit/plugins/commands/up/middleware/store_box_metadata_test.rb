# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)
require Vagrant.source_root.join("plugins/commands/up/middleware/store_box_metadata")

describe VagrantPlugins::CommandUp::StoreBoxMetadata do
  include_context "unit"

  let(:app) { double("app") }
  let(:machine) { double("machine", box: box) }
  let(:box) {
    double("box",
      name: box_name,
      version: box_version,
      provider: box_provider,
      directory: box_directory
    )
  }
  let(:box_name) { "BOX_NAME" }
  let(:box_version) { "1.0.0" }
  let(:box_provider) { "dummy" }
  let(:box_directory) { File.join(vagrant_user_data_path, box_directory_relative) }
  let(:box_directory_relative) { File.join("boxes", "BOX_NAME") }
  let(:vagrant_user_data_path) { "/vagrant/user/data" }
  let(:meta_path) { "META_PATH" }
  let(:env) { {machine: machine} }

  let(:subject) { described_class.new(app, env) }

  describe "#call" do
    context "with no box file" do
      let(:machine) { double("machine", name: "guest", provider_name: "provider") }
      let(:env) { {machine: machine} }

      before do
        allow(machine).to receive(:box).and_return(nil)
        expect(app).to receive(:call).with(env)
      end


      it "does not write the metadata file" do
        expect(File).to_not receive(:open)
        subject.call(env)
      end
    end

    let(:meta_file) { double("meta_file") }

    before do
      allow(Vagrant).to receive(:user_data_path).and_return(vagrant_user_data_path)
      allow(machine).to receive(:data_dir).and_return(meta_path)
      allow(meta_path).to receive(:join).with("box_meta").and_return(meta_path)
      allow(File).to receive(:open)
      expect(app).to receive(:call).with(env)
    end

    after { subject.call(env) }

    it "should open a metadata file" do
      expect(File).to receive(:open).with(meta_path, anything)
    end

    context "contents of metadata file" do

      before { expect(File).to receive(:open).with(meta_path, anything).and_yield(meta_file) }

      it "should be JSON data" do
        expect(meta_file).to receive(:write) do |data|
          val = JSON.parse(data)
          expect(val).to be_a(Hash)
        end
      end

      it "should include box name" do
        expect(meta_file).to receive(:write) do |data|
          val = JSON.parse(data)
          expect(val["name"]).to eq(box_name)
        end
      end

      it "should include box version" do
        expect(meta_file).to receive(:write) do |data|
          val = JSON.parse(data)
          expect(val["version"]).to eq(box_version)
        end
      end

      it "should include box provider" do
        expect(meta_file).to receive(:write) do |data|
          val = JSON.parse(data)
          expect(val["provider"]).to eq(box_provider)
        end
      end

      it "should include relative box directory" do
        expect(meta_file).to receive(:write) do |data|
          val = JSON.parse(data)
          expect(val["directory"]).to eq(box_directory_relative)
        end
      end
    end
  end
end
