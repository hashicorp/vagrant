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

  s.add_dependency "childprocess", "~> 0.3.7"
  s.add_dependency "erubis", "~> 2.7.0"
  s.add_dependency "i18n", "~> 0.6.0"
  s.add_dependency "log4r", "~> 1.1.9"
  s.add_dependency "net-ssh", "~> 2.6.6"
  s.add_dependency "net-scp", "~> 1.1.0"

  s.add_development_dependency "rake"
  s.add_development_dependency "contest", ">= 0.1.2"
  s.add_development_dependency "minitest", "~> 2.5.1"
  s.add_development_dependency "mocha"
  # This has problems on Windows, we need to find a better way:
  # s.add_development_dependency "sys-proctable", "~> 0.9.0"
  s.add_development_dependency "rspec-core", "~> 2.11.0"
  s.add_development_dependency "rspec-expectations", "~> 2.11.0"
  s.add_development_dependency "rspec-mocks", "~> 2.11.0"

  # The following block of code determines the files that should be included
  # in the gem. It does this by reading all the files in the directory where
  # this gemspec is, and parsing out the ignored files from the gitignore.
  # Note that the entire gitignore(5) syntax is not supported, specifically
  # the "!" syntax, but it should mostly work correctly.
  root_path      = File.dirname(__FILE__)
  all_files      = Dir.chdir(root_path) { Dir.glob("**/{*,.*}") }
  all_files.reject! { |file| [".", ".."].include?(File.basename(file)) }
  gitignore_path = File.join(root_path, ".gitignore")
  gitignore      = File.readlines(gitignore_path)
  gitignore.map!    { |line| line.chomp.strip }
  gitignore.reject! { |line| line.empty? || line =~ /^(#|!)/ }

  unignored_files = all_files.reject do |file|
    # Ignore any directories, the gemspec only cares about files
    next true if File.directory?(file)

    # Ignore any paths that match anything in the gitignore. We do
    # two tests here:
    #
    #   - First, test to see if the entire path matches the gitignore.
    #   - Second, match if the basename does, this makes it so that things
    #     like '.DS_Store' will match sub-directories too (same behavior
    #     as git).
    #
    gitignore.any? do |ignore|
      File.fnmatch(ignore, file, File::FNM_PATHNAME) ||
        File.fnmatch(ignore, File.basename(file), File::FNM_PATHNAME)
    end
  end

  s.files         = unignored_files
  s.executables   = unignored_files.map { |f| f[/^bin\/(.*)/, 1] }.compact
  s.require_path  = 'lib'
end
