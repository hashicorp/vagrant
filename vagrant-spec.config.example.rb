Vagrant::Spec::Acceptance.configure do |c|
  c.provider "virtualbox",
    box_basic: "/Users/mitchellh/Downloads/package.box"
end
