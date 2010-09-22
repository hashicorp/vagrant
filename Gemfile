source "http://rubygems.org"

gem "vagrant", :path => '.'

# Use the following gems straight from git, since Vagrant dev
# typically coincides with it
gem "virtualbox", :git => "git://github.com/mitchellh/virtualbox.git"

# Gems required for testing only. To install run
# gem bundle test
group :test do
  gem "rake"
  gem "contest", ">= 0.1.2"
  gem "mocha"

  # For documentation
  gem "yard", "~> 0.6.1"
  gem "bluecloth"

  platforms :mri_18 do
    gem "ruby-debug"
  end

  platforms :mri_19 do
    gem "ruby-debug19"
  end
end
