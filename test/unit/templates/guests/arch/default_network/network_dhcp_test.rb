# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require "vagrant/util/template_renderer"

describe "templates/guests/arch/default_network/network_dhcp" do
  let(:template) { "guests/arch/default_network/network_dhcp" }

  it "renders the template" do
    result = Vagrant::Util::TemplateRenderer.render(template, options: {
      device: "eth1",
    })
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      Description='A basic dhcp ethernet connection'
      Interface=eth1
      Connection=ethernet
      IP=dhcp
    EOH
  end
end
