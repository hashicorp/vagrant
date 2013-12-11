require_relative "test/acceptance/base"

Vagrant::Spec::Acceptance.configure do |c|
  c.provider "virtualbox",
    box: "<PATH TO MINIMAL BOX>",
    contexts: ["provider-context/virtualbox"]
end
