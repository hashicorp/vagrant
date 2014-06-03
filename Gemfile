source "https://rubygems.org"

gemspec
# f4ece43: Allow the user to disable SSL peer verification.
gem 'winrm', git: 'https://github.com/WinRb/WinRM.git', ref: 'f4ece4384df2768bc7756c3c5c336db65b05c674'

if File.exist?(File.expand_path("../../vagrant-spec", __FILE__))
  gem 'vagrant-spec', path: "../vagrant-spec"
else
  gem 'vagrant-spec', git: "https://github.com/mitchellh/vagrant-spec.git"
end
