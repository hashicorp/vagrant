# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require "vagrant/util/template_renderer"

describe "templates/guests/arch/default_network/network_static" do
  let(:template) { "guests/arch/default_network/network_static" }

  it "renders the template" do
    result = Vagrant::Util::TemplateRenderer.render(template, options: {
      device:  "eth1",
      ip:      "1.1.1.1",
      netmask: "24",
    })
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      Connection=ethernet
      Description='A basic static ethernet connection'
      Interface=eth1
      IP=static
      Address=('1.1.1.1/24')
    EOH
  end

  it "includes the gateway" do
    result = Vagrant::Util::TemplateRenderer.render(template, options: {
      device:  "eth1",
      ip:      "1.1.1.1",
      gateway: "1.2.3.4",
      netmask: "24",
    })
    expect(result).to eq <<-EOH.gsub(/^ {6}/, "")
      Connection=ethernet
      Description='A basic static ethernet connection'
      Interface=eth1
      IP=static
      Address=('1.1.1.1/24')
      Gateway='1.2.3.4'
    EOH
  end
end
