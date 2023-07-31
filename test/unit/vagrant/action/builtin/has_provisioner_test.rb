# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)


describe Vagrant::Action::Builtin::HasProvisioner do
  include_context "unit"

  let(:provisioner_one) { double("provisioner_one") }
  let(:provisioner_two) { double("provisioner_two") }
  let(:provisioners) { [provisioner_one, provisioner_two] }
  let(:machine) { double("machine") }
  let(:ui) { Vagrant::UI::Silent.new }
  let(:env)    {{ machine: machine, ui: ui, root_path: Pathname.new(".") }}
  let(:app)    { lambda { |*args| }}

  subject { described_class.new(app, env) }

  describe "#call" do
    before do
      allow(provisioner_one).to receive(:communicator_required).and_return(true)
      allow(provisioner_one).to receive(:name)
      allow(provisioner_one).to receive(:type)
      allow(provisioner_two).to receive(:communicator_required).and_return(false)
      allow(provisioner_two).to receive(:name)
      allow(provisioner_two).to receive(:type)
      allow(machine).to receive_message_chain(:config, :vm, :provisioners).and_return(provisioners)
    end

    context "provider has capability :has_communicator" do
      before do
        allow(machine).to receive_message_chain(:provider, :capability?).with(:has_communicator).and_return(true)
      end

      it "does not skip any provisioners if provider has ssh" do
        allow(machine).to receive_message_chain(:provider, :capability).with(:has_communicator).and_return(true)
        expect(provisioner_one).to_not receive(:communicator_required)
        expect(provisioner_two).to_not receive(:communicator_required)

        subject.call(env)
        expect(env[:skip]).to eq([])
      end

      it "skips provisioners that require a communicator if provider does not have ssh" do
        allow(machine).to receive_message_chain(:provider, :capability).with(:has_communicator).and_return(false)
        expect(provisioner_one).to receive(:communicator_required)
        expect(provisioner_two).to receive(:communicator_required)
        expect(provisioner_one).to receive(:run=).with(:never)

        subject.call(env)
        expect(env[:skip]).to eq([provisioner_one])
      end
    end

    context "provider does not have capability :has_communicator" do
      before do
        allow(machine).to receive_message_chain(:provider, :capability?).with(:has_communicator).and_return(false)
      end

      it "does not skip any provisioners" do
        expect(provisioner_one).to_not receive(:communicator_required)
        expect(provisioner_two).to_not receive(:communicator_required)
        subject.call(env)
        expect(env[:skip]).to eq([])
      end
    end
  end
end
