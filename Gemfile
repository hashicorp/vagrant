source "https://rubygems.org"

gemspec

if File.exist?(File.expand_path("../../vagrant-spec", __FILE__))
  gem 'vagrant-spec', path: "../vagrant-spec"
else
  gem 'vagrant-spec', git: "https://github.com/mitchellh/vagrant-spec.git", :ref => '2f0fb10862b2d19861c584be9d728080ba1f5d33'
end
