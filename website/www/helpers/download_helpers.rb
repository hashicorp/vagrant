require "net/http"

$vagrant_files = {}
$vagrant_os = []

$vagrant_os_mappings = {
  ".deb" => "debian",
  ".dmg" => "darwin",
  ".msi" => "windows",
  ".rpm" => "rpm",
}

$vagrant_os_order  = ["darwin", "windows", "debian", "rpm"]
$vagrant_downloads = {}
$vagrant_versions  = []

if ENV["VAGRANT_VERSION"]
  puts "Finding downloads for Vagrant"
  raise "BINTRAY_API_KEY must be set." if !ENV["BINTRAY_API_KEY"]
  http = Net::HTTP.new("dl.bintray.com", 80)
  req = Net::HTTP::Get.new("/mitchellh/vagrant/")
  req.basic_auth "mitchellh", ENV["BINTRAY_API_KEY"]
  response = http.request(req)

  response.body.split("\n").each do |line|
    next if line !~ /\/mitchellh\/vagrant\/(.+?)'/
    filename = $1.to_s

    # Ignore any files that don't appear to have a version in it
    next if filename !~ /[-_]?(\d+\.\d+\.\d+[^-_.]*)/
    version = Gem::Version.new($1.to_s)
    $vagrant_downloads[version] ||= {}

    $vagrant_os_mappings.each do |suffix, os|
      if filename.end_with?(suffix)
        $vagrant_downloads[version][os] ||= []
        $vagrant_downloads[version][os] << filename
      end
    end
  end

  $vagrant_versions = $vagrant_downloads.keys.sort.reverse
  $vagrant_versions.each do |v|
    puts "- Version #{v} found"
  end
else
  puts "Not generating downloads."
end

module DownloadHelpers
  def download_arch(file)
    if file.include?("i686")
      return "32-bit"
    elsif file.include?("x86_64")
      return "64-bit"
    else
      return "Universal (32 and 64-bit)"
    end
  end

  def download_os_human(os)
    if os == "darwin"
      return "Mac OS X"
    elsif os == "debian"
      return "Linux (Deb)"
    elsif os == "rpm"
      return "Linux (RPM)"
    elsif os == "windows"
      return "Windows"
    else
      return os
    end
  end

  def download_url(file)
    "https://dl.bintray.com/mitchellh/vagrant/#{file}"
  end

  def latest_version
    $vagrant_versions.first
  end
end
