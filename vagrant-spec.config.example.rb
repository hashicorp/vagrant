require_relative "test/acceptance/base"

Vagrant::Spec::Acceptance.configure do |c|
  c.provider "virtualbox",
    box_basic: "<PATH TO MINIMAL BOX>",
    contexts: ["provider/virtualbox"]
end
