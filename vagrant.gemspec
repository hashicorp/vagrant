$:.unshift File.expand_path("../lib", __FILE__)
require "vagrant/version"

Gem::Specification.new do |s|
  s.name          = "vagrant"
  s.version       = Vagrant::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Mitchell Hashimoto", "John Bender"]
  s.email         = ["mitchell.hashimoto@gmail.com", "john.m.bender@gmail.com"]
  s.homepage      = "https://www.vagrantup.com"
  s.license       = 'MIT'
  s.summary       = "Build and distribute virtualized development environments."
  s.description   = "Vagrant is a tool for building and distributing virtualized development environments."

  s.required_ruby_version     = "~> 2.2"
  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "vagrant"

  # Do not update the Bundler constraint. Vagrant relies on internal Bundler
  # APIs, so even point releases can introduce breaking changes. These changes
  # are *untestable* until after a release is made because there is no way for
  # Bundler to exec into itself. Please do not update the Bundler constraint.
  s.add_dependency "bundler", "= 1.12.5"
  s.add_dependency "childprocess", "~> 0.5.0"
  s.add_dependency "erubis", "~> 2.7.0"
  s.add_dependency "i18n", ">= 0.6.0", "<= 0.8.0"
  s.add_dependency "listen", "~> 3.1.5"
  s.add_dependency "hashicorp-checkpoint", "~> 0.1.1"
  s.add_dependency "log4r", "~> 1.1.9", "< 1.1.11"
  s.add_dependency "net-ssh", "~> 3.0.1"
  s.add_dependency "net-sftp", "~> 2.1"
  s.add_dependency "net-scp", "~> 1.1.0"
  s.add_dependency "rb-kqueue", "~> 0.2.0"
  s.add_dependency "rest-client", ">= 1.6.0", "< 3.0"
  s.add_dependency "wdm", "~> 0.1.0"
  s.add_dependency "winrm", "~> 1.6"
  s.add_dependency "winrm-fs", "~> 0.3.0"

  # We lock this down to avoid compilation issues.
  s.add_dependency "nokogiri", "= 1.6.7.1"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 2.14.0"
  s.add_development_dependency "webmock", "~> 1.20"
  s.add_development_dependency "fake_ftp", "~> 0.1"

  # The following block of code determines the files that should be included
  # in the gem. It does this by reading all the files in the directory where
  # this gemspec is, and parsing out the ignored files from the gitignore.
  # Note that the entire gitignore(5) syntax is not supported, specifically
  # the "!" syntax, but it should mostly work correctly.
  root_path      = File.dirname(__FILE__)
  all_files      = Dir.chdir(root_path) { Dir.glob("**/{*,.*}") }
  all_files.reject! { |file| [".", ".."].include?(File.basename(file)) }
  all_files.reject! { |file| file.start_with?("website/") }
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
