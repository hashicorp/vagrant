$:.unshift File.expand_path("../lib", __FILE__)
require "vagrant/version"

Gem::Specification.new do |s|
  s.name          = "vagrant"
  s.version       = Vagrant::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Mitchell Hashimoto", "John Bender"]
  s.email         = ["mitchell.hashimoto@gmail.com", "john.m.bender@gmail.com"]
  s.homepage      = "http://vagrantup.com"
  s.summary       = "Build and distribute virtualized development environments."
  s.description   = "Vagrant is a tool for building and distributing virtualized development environments."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "vagrant"

  s.add_dependency "archive-tar-minitar", "= 0.5.2"
  s.add_dependency "erubis", "~> 2.7.0"
  s.add_dependency "json", "~> 1.5.1"
  s.add_dependency "log4r", "~> 1.1.9"
  s.add_dependency "net-ssh", "~> 2.1.4"
  s.add_dependency "net-scp", "~> 1.0.4"
  s.add_dependency "i18n", "~> 0.6.0"
  s.add_dependency "virtualbox", "~> 0.9.1"

  s.add_development_dependency "rake"
  s.add_development_dependency "contest", ">= 0.1.2"
  s.add_development_dependency "minitest", "~> 2.5.1"
  s.add_development_dependency "mocha"
  s.add_development_dependency "childprocess", "~> 0.2.3"
  s.add_development_dependency "sys-proctable", "~> 0.9.0"
  s.add_development_dependency "rspec-core", "~> 2.7.1"
  s.add_development_dependency "rspec-expectations", "~> 2.7.0"
  s.add_development_dependency "rspec-mocks", "~> 2.7.0"

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path  = 'lib'
end

