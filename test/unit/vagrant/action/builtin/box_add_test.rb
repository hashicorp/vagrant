require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::BoxAdd do
  let(:app) { lambda { |env| } }
  let(:env) { {} }

  subject { described_class.new(app, env) }
end
