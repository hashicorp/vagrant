# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V2::SyncedFolder::Collection do
  include_context "unit"

  let(:folders) { described_class[
    :nfs=>
      {"/other"=>
        {:type=>:nfs, :guestpath=>"/other", :hostpath=>"/other", :disabled=>false, :__vagrantfile=>true, plugin:"someclass"},
       "/tests"=>
        {:type=>:nfs, :guestpath=>"/tests", :hostpath=>"/tests", :disabled=>false, :__vagrantfile=>true, plugin:"someclass"}},
    :virtualbox=>
      {"/vagrant"=>
        {:guestpath=>"/vagrant", :hostpath=>"/vagrant", :disabled=>false, :__vagrantfile=>true, plugin:"someotherclass"}}
  ]}
  
  describe "#types" do
    it "gets all the types of synced folders" do 
      expect(folders.types).to eq([:nfs, :virtualbox])
    end
  end

  describe "#type" do
    it "returns the plugin for a type" do 
      expect(folders.type(:nfs)).to eq("someclass")
      expect(folders.type(:virtualbox)).to eq("someotherclass")
    end
  end

  describe "to_h" do
    it "removed plugin key" do 
      original_folders = folders
      folders_h = folders.to_h
      folders_h.values.each do |v|
        v.values.each do |w|
          expect(w).not_to include(:plugin)
        end
      end
      original_folders.values.each do |v|
        v.values.each do |w|
          expect(w).to include(:plugin)
        end
      end
    end
  end
end
