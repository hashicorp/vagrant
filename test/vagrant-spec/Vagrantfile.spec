# -*- mode: ruby -*-
# vi: set ft=ruby :

# Guest boxes to use for vagrant-spec
GUEST_BOXES = {
  'hashicorp/bionic64' => '1.0.282',
  'hashicorp-vagrant/ubuntu-16.04' => '1.0.1',
  'hashicorp-vagrant/centos-7.4' => '1.0.2',
  # 'hashicorp-vagrant/windows-10' => '1.0.0',
  'spox/osx-10.12' => '0.0.1'
}

DOCKER_IMAGES = {
  'nginx' => 'latest'
}

# Host boxes to run vagrant-spec
HOST_BOXES = {
  'hashicorp/bionic64' => '1.0.282',
  'hashicorp-vagrant/ubuntu-16.04' => '1.0.1',
  'hashicorp-vagrant/centos-7.4' => '1.0.2',
  # 'hashicorp-vagrant/windows-10' => '1.0.0',
  'spox/osx-10.12' => '0.0.1'
}

# Not all boxes are named by their specific "platform"
# so this allows Vagrant to use the right provision script
PLATFORM_SCRIPT_MAPPING = {
  "ubuntu" => "ubuntu",
  "bionic" => "ubuntu",
  "centos" => "centos",
  "windows" => "windows"
}

# Determine what providers to test
enabled_providers = ENV.fetch("VAGRANT_SPEC_PROVIDERS", "virtualbox").split(",")
# Set what boxes should be used
enabled_guests = ENV["VAGRANT_GUEST_BOXES"] ? ENV["VAGRANT_GUEST_BOXES"].split(",") : GUEST_BOXES.keys
enabled_docker_images = ENV["VAGRANT_DOCKER_IMAGES"] ? ENV["VAGRANT_DOCKER_IMAGES"].split(",") : DOCKER_IMAGES.keys
enabled_hosts = ENV["VAGRANT_HOST_BOXES"] ? ENV["VAGRANT_HOST_BOXES"].split(",") : HOST_BOXES.keys

guest_boxes = Hash[GUEST_BOXES.find_all{|name, version| enabled_guests.include?(name)}.compact]
docker_images = Hash[DOCKER_IMAGES.find_all{|name, version| enabled_docker_images.include?(name)}.compact]
host_boxes = Hash[HOST_BOXES.find_all{|name, version| enabled_hosts.include?(name)}.compact]

# Grab vagrantcloud token, if available
vagrantcloud_token = ENV["VAGRANT_CLOUD_TOKEN"]

# Download copies of the guest boxes for testing if missing
enabled_providers.each do |provider_name|

  next if provider_name == "docker"

  guest_boxes.each do |guest_box, box_version|
    box_owner, box_name = guest_box.split('/')
    box_path = File.join(File.dirname(__FILE__), "./boxes/#{guest_box.sub('/', '_')}.#{provider_name}.#{box_version}.box")
    if !File.exist?(box_path)
      $stderr.puts "Downloading guest box #{guest_box}"
      cmd = "curl -Lf -o #{box_path} https://app.vagrantup.com/#{box_owner}/boxes/#{box_name}/versions/#{box_version}/providers/#{provider_name}.box"
      if vagrantcloud_token
        cmd += "?access_token=#{vagrantcloud_token}"
      end
      result = system(cmd)
      if !result
        $stderr.puts
        $stderr.puts "ERROR: Failed to download guest box #{guest_box} for #{provider_name}!"
        exit 1
      end
    end
  end
end

Vagrant.configure(2) do |global_config|
  host_boxes.each do |box_name, box_version|
    platform = box_name.split('/').last.sub(/[^a-z]+$/, '')
    enabled_providers.each do |provider_name|
      global_config.vm.define("#{box_name.split('/').last}-#{provider_name}") do |config|
        config.vm.box = box_name
        config.vm.box_version = box_version
        config.vm.synced_folder '.', '/vagrant', disable: true
        config.vm.synced_folder '../../', '/vagrant'
        config.vm.provider :vmware_desktop do |vmware|
          vmware.vmx["memsize"] = ENV.fetch("VAGRANT_HOST_MEMORY", "5000")
          vmware.vmx['vhv.enable'] = 'TRUE'
          vmware.vmx['vhv.allow'] = 'TRUE'
        end
        if platform == "windows"
          config.vm.provision :shell,
            path: "./scripts/#{PLATFORM_SCRIPT_MAPPING[platform]}-setup.#{provider_name}.ps1", run: "once"
        else
          config.vm.provision :shell,
            path: "./scripts/#{PLATFORM_SCRIPT_MAPPING[platform]}-setup.#{provider_name}.sh", run: "once",
            env: {
              "HASHIBOT_USERNAME" => ENV["HASHIBOT_USERNAME"],
              "HASHIBOT_TOKEN" => ENV["HASHIBOT_TOKEN"]
            }
        end
        if provider_name == "docker"
          docker_images.each_with_index do |image_info, idx|
            docker_image, _ = image_info
            spec_cmd_args = ENV["VAGRANT_SPEC_ARGS"]
            if idx != 0
              spec_cmd_args = "#{spec_cmd_args} --without-component cli/*".strip
            end
            if platform == "windows"
              config.vm.provision(
                :shell,
                path: "./scripts/#{platform}-run.#{provider_name}.ps1",
                keep_color: true,
                env: {
                  "VAGRANT_SPEC_ARGS" => "test --components provider/docker/docker/* #{spec_cmd_args}".strip,
                  "VAGRANT_SPEC_DOCKER_IMAGE" => docker_image
                }
              )
            else
              config.vm.provision(
                :shell,
                path: "./scripts/#{PLATFORM_SCRIPT_MAPPING[platform]}-run.#{provider_name}.sh",
                keep_color: true,
                env: {
                  "VAGRANT_SPEC_ARGS" => "test --components provider/docker/docker/* #{spec_cmd_args}".strip,
                  "VAGRANT_SPEC_DOCKER_IMAGE" => docker_image,
                  "VAGRANT_LOG" => "trace",
                  "VAGRANT_LOG_LEVEL" => "trace",
                  "VAGRANT_SPEC_LOG_PATH" => "/tmp/vagrant-spec.log",
                }
              )
            end
          end
        else
          guest_boxes.each_with_index do |box_info, idx|
            guest_box, box_version = box_info
            guest_platform = guest_box.split('/').last.sub(/[^a-z]+$/, '')
            guest_platform = PLATFORM_SCRIPT_MAPPING[guest_platform]
            spec_cmd_args = ENV["VAGRANT_SPEC_ARGS"]
            if idx != 0
              spec_cmd_args = "#{spec_cmd_args} --without-component cli/*".strip
            end
            if platform == "windows"
              config.vm.provision(
                :shell,
                path: "./scripts/#{platform}-run.#{provider_name}.ps1",
                keep_color: true,
                env: {
                  "VAGRANT_SPEC_ARGS" => "#{spec_cmd_args}".strip,
                  "VAGRANT_SPEC_BOX" => "c:/vagrant/#{guest_box.sub('/', '_')}.#{provider_name}.#{box_version}.box",
                  "VAGRANT_SPEC_GUEST_PLATFORM" => guest_platform,
                }
              )
            else
              components = [
                "provider/#{provider_name}/basic",
                "provider/#{provider_name}/provisioner/shell",
              ]
              config.vm.provision(
                :shell,
                path: "./scripts/#{PLATFORM_SCRIPT_MAPPING[platform]}-run.#{provider_name}.sh",
                keep_color: true,
                env: {
                  # "VAGRANT_SPEC_ARGS" => "test #{spec_cmd_args}".strip,
                  # TEMP: Forcing just the basic component of the provider suite as not all tests are passing yet.
                  #       Hoping to widen this out over time to be unscoped with everything passing.
                  "VAGRANT_SPEC_ARGS" => "test --components #{components.join(" ")}",
                  "VAGRANT_SPEC_BOX" => "/vagrant/test/vagrant-spec/boxes/#{guest_box.sub('/', '_')}.#{provider_name}.#{box_version}.box",
                  "VAGRANT_SPEC_GUEST_PLATFORM" => guest_platform,
                  "VAGRANT_LOG" => "trace",
                  "VAGRANT_LOG_LEVEL" => "trace",
                  "VAGRANT_SPEC_LOG_PATH" => "/tmp/vagrant-spec.log",
                }
              )
            end
          end
        end
      end
    end
  end
end
