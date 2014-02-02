module Vagrant
  # This will always be up to date with the current version of Vagrant,
  # since it is used to generate the gemspec and is also the source of
  # the version for `vagrant -v`
  VERSION = File.read(
    File.expand_path("../../../version.txt", __FILE__)).chomp
end
