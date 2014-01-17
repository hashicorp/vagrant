source "http://rubygems.org"

gemspec

gem 'childprocess', git: "https://github.com/jarib/childprocess.git",
  branch: "windows-inherit-stdin"

if File.exist?(File.expand_path("../../vagrant-spec", __FILE__))
  gem 'vagrant-spec', path: "../vagrant-spec"
else
  gem 'vagrant-spec', git: "https://github.com/mitchellh/vagrant-spec.git"
end
