require "net/http"

$vagrant_files = {}
$vagrant_os = []

$vagrant_os_mappings = {
  ".deb" => "debian",
  ".dmg" => "darwin",
  ".msi" => "windows",
  ".rpm" => "rpm",
}

if ENV["VAGRANT_VERSION"]
  raise "BINTRAY_API_KEY must be set." if !ENV["BINTRAY_API_KEY"]
  http = Net::HTTP.new("dl.bintray.com", 80)
  req = Net::HTTP::Get.new("/mitchellh/vagrant")
  req.basic_auth "mitchellh", ENV["BINTRAY_API_KEY"]
  response = http.request(req)

  response.body.split("\n").each do |line|
    next if line !~ /\/mitchellh\/vagrant\/(.+?)'/
    filename = $1.to_s
    $vagrant_os_mappings.each do |suffix, os|
      if filename.end_with?(suffix)
        $vagrant_files[os] ||= []
        $vagrant_files[os] << filename
      end
    end
  end

  $vagrant_os = $vagrant_files.keys
  $vagrant_files.each do |key, value|
    value.sort!
  end
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
      return "Debian / Ubuntu"
    elsif os == "rpm"
      return "CentOS / RedHat / Fedora"
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
    ENV["VAGRANT_VERSION"]
  end
end
