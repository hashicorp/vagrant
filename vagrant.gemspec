# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib/", __FILE__)
$:.unshift(lib) unless $:.include?(lib)

require 'vagrant/version'

Gem::Specification.new do |s|
  s.name          = "vagrant"
  s.version       = Vagrant::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Mitchell Hashimoto", "John Bender"]
  s.email         = ["mitchell.hashimoto@gmail.com", "john.m.bender@gmail.com"]
  s.homepage      = "http://vagrantup.com"
  s.summary       = "Build and distribute virtualized development environments."
  s.description   = "Vagrant is a tool for building and distributing virtualized development environments."
  s.executables   = ["vagrant"]
  s.require_paths = ["lib"]
  s.files         = Dir.glob("{bin,config,keys,lib,templates}/**/*") + %W[LICENSE README.md]
  s.rubyforge_project = "vagrant"

  s.add_dependency("virtualbox", "~> 0.7.3")
  s.add_dependency("net-ssh", ">= 2.0.19")
  s.add_dependency("net-scp", ">= 1.0.2")
  s.add_dependency("json", ">= 1.4.3")
  s.add_dependency("archive-tar-minitar", "= 0.5.2")
  s.add_dependency("mario", "~> 0.0.6")
  s.add_dependency("erubis", ">= 2.6.6")

  s.add_development_dependency("rake")
  s.add_development_dependency("contest", ">= 0.1.2")
  s.add_development_dependency("mocha")
  s.add_development_dependency("ruby-debug")
end

