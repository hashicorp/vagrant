# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../base"

require "vagrant/util/template_renderer"

describe "templates/guests/nixos/network" do
  let(:template) { "guests/nixos/network" }

  it "renders the template" do
    result = Vagrant::Util::TemplateRenderer.render(template, networks: [{
      device: "en0",
      ip: "1.1.1.1",
      prefix_length: "24",
      type: :static,
    }])
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      { config, pkgs, ... }:
      {
        networking.interfaces = {
          en0.ipv4.addresses = [{
            address = "1.1.1.1";
            prefixLength = 24;
          }];
        };
      }
      EOH
  end
end
