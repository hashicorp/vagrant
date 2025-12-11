# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

source "https://rubygems.org"

gemspec

if File.exist?(File.expand_path("../../vagrant-spec", __FILE__))
  gem 'vagrant-spec', path: "../vagrant-spec"
else
  gem 'vagrant-spec', git: "https://github.com/hashicorp/vagrant-spec.git", branch: :main
end
