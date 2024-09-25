# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require_relative "../../../base"

require Vagrant.source_root.join("plugins/providers/docker/driver")

describe VagrantPlugins::DockerProvider::Driver do
  let(:cmd_executed) { @cmd }
  let(:cid)          { 'side-1-song-10' }
  let(:execute_result) {
    double("execute_result",
      exit_code: exit_code,
      stderr: stderr,
      stdout: stdout
    )
  }
  let(:exit_code) { 0 }
  let(:stderr) { "" }
  let(:stdout) { "" }

  before do
    allow(Vagrant::Util::Subprocess).to receive(:execute) { |*args|
      if args.last.is_a?(Hash)
        args = args[0, args.size - 1]
      end
      invalid = args.detect { |a| !a.is_a?(String) }
      if invalid
        raise TypeError,
          "Vagrant::Util::Subprocess#execute only accepts signle option Hash and String arguments, received `#{invalid.class}'"
      end
      @cmd = args.join(" ")
    }.and_return(execute_result)
    allow_any_instance_of(Vagrant::Errors::VagrantError).
      to receive(:translate_error) { |*args| args.join(" ") }
  end

  let(:docker_network_struct) {
[
    {
        "Name": "bridge",
        "Id": "ae74f6cc18bbcde86326937797070b814cc71bfc4a6d8e3e8cf3b2cc5c7f4a7d",
        "Created": "2019-03-20T14:10:06.313314662-07:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": nil,
            "Config": [
                {
                    "Subnet": "172.17.0.0/16",
                    "Gateway": "172.17.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "a1ee9b12bcea8268495b1f43e8d1285df1925b7174a695075f6140adb9415d87": {
                "Name": "vagrant-sandbox_docker-1_1553116237",
                "EndpointID": "fc1b0ed6e4f700cf88bb26a98a0722655191542e90df3e3492461f4d1f3c0cae",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.bridge.default_bridge": "true",
            "com.docker.network.bridge.enable_icc": "true",
            "com.docker.network.bridge.enable_ip_masquerade": "true",
            "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
            "com.docker.network.bridge.name": "docker0",
            "com.docker.network.driver.mtu": "1500"
        },
        "Labels": {}
    },
    {
        "Name": "host",
        "Id": "2a2845e77550e33bf3e97bda8b71477ac7d3ccf78bc9102585fdb6056fb84cbf",
        "Created": "2018-09-28T10:54:08.633543196-07:00",
        "Scope": "local",
        "Driver": "host",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": nil,
            "Config": []
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {},
        "Labels": {}
    },
    {
        "Name": "vagrant_network",
        "Id": "93385d4fd3cf7083a36e62fa72a0ad0a21203d0ddf48409c32b550cd8462b3ba",
        "Created": "2019-03-20T14:10:36.828235585-07:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.18.0.0/16",
                    "Gateway": "172.18.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "a1ee9b12bcea8268495b1f43e8d1285df1925b7174a695075f6140adb9415d87": {
                "Name": "vagrant-sandbox_docker-1_1553116237",
                "EndpointID": "9502cd9d37ae6815e3ffeb0bc2de9b84f79e7223e8a1f8f4ccc79459e96c7914",
                "MacAddress": "02:42:ac:12:00:02",
                "IPv4Address": "172.18.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    },
    {
        "Name": "vagrant_network_172.20.0.0/16",
        "Id": "649f0ab3ef0eef6f2a025c0d0398bd7b9b4d05ec88b0d7bd573b44153d903cfb",
        "Created": "2019-03-20T14:10:37.088885647-07:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.20.0.0/16"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "a1ee9b12bcea8268495b1f43e8d1285df1925b7174a695075f6140adb9415d87": {
                "Name": "vagrant-sandbox_docker-1_1553116237",
                "EndpointID": "e19156f8018f283468227fa97c145f4ea0eaba652fb7e977a0c759b1c3ec168a",
                "MacAddress": "02:42:ac:14:80:02",
                "IPv4Address": "172.20.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
].to_json }


  describe '#build' do
    let(:stdout) { "Successfully built other_package\nSuccessfully built 1a2b3c4d" }
    let(:cid) { "1a2b3c4d" }

    it "builds a container with standard docker" do
      container_id = subject.build("/tmp/fakedir")

      expect(container_id).to eq(cid)
    end

    context "using buildkit" do
      let(:stdout) { "writing image sha256:1a2b3c4d 0.0s done" }

      it "builds a container with buildkit docker" do
        container_id = subject.build("/tmp/fakedir")

        expect(container_id).to eq(cid)
      end
    end

    context "using buildkit with old output" do
      let(:stdout) { "writing image sha256:1a2b3c4d done" }

      it "builds a container with buildkit docker (old output)" do
        container_id = subject.build("/tmp/fakedir")

        expect(container_id).to eq(cid)
      end
    end

    context "using buildkit with containerd backend output" do
      let(:stdout) { "exporting manifest list sha256:1a2b3c4d done" }

      it "builds a container with buildkit docker (containerd)" do
        container_id = subject.build("/tmp/fakedir")

        expect(container_id).to eq(cid)
      end
    end

    context "using podman emulating docker CLI" do
      let(:stdout) { "1a2b3c4d5e6f7g8h9i10j11k12l13m14n16o17p18q19r20s21t22u23v24w25x2" }

      it "builds a container with podman emulating docker CLI" do
        allow(subject).to receive(:podman?).and_return(true)

        container_id = subject.build("/tmp/fakedir")

        expect(container_id).to eq(cid)
      end

      context "if output contains extra trailing information" do
        let(:stdout) { "1a2b3c4d5e6f7g8h9i10j11k12l13m14n16o17p18q19r20s21t22u23v24w25x2\nextra content\n" }
        it "builds a container with podman emulating docker CLI" do
          allow(subject).to receive(:podman?).and_return(true)

          container_id = subject.build("/tmp/fakedir")

          expect(container_id).to eq(cid)
        end
      end
    end
  end

  describe '#podman?' do
    context "when docker is used" do
      let(:stdout) { "Docker version 1.8.1, build d12ea79" }

      it 'returns false' do
        expect(subject.podman?).to be false
      end
    end
    context "when podman is used" do
      let(:stdout) { "podman version 1.7.1-dev" }

      it 'returns true' do
        expect(subject.podman?).to be true
      end
    end
  end

  describe '#create' do
    let(:params) { {
      image:      'jimi/hendrix:electric-ladyland',
      cmd:        ['play', 'voodoo-chile'],
      ports:      '8080:80',
      volumes:    '/host/path:guest/path',
      detach:     true,
      links:      [[:janis, 'joplin'], [:janis, 'janis']],
      env:        {key: 'value'},
      name:       cid,
      hostname:   'jimi-hendrix',
      privileged: true
    } }

    before { subject.create(params) }

    it 'runs a detached docker image' do
      expect(cmd_executed).to match(/^docker run .+ -d .+ #{Regexp.escape params[:image]}/)
    end

    it 'sets container name' do
      expect(cmd_executed).to match(/--name #{Regexp.escape params[:name]}/)
    end

    it 'forwards ports' do
      expect(cmd_executed).to match(/-p #{params[:ports]} .+ #{Regexp.escape params[:image]}/)
    end

    it 'shares folders' do
      expect(cmd_executed).to match(/-v #{params[:volumes]} .+ #{Regexp.escape params[:image]}/)
    end

    it 'links containers' do
      params[:links].each do |link|
        expect(cmd_executed).to match(/--link #{link.join(':')} .+ #{Regexp.escape params[:image]}/)
      end
    end

    it 'sets environmental variables' do
      expect(cmd_executed).to match(/-e key=value .+ #{Regexp.escape params[:image]}/)
    end

    it 'is able to run a privileged container' do
      expect(cmd_executed).to match(/--privileged .+ #{Regexp.escape params[:image]}/)
    end

    it 'sets the hostname if specified' do
      expect(cmd_executed).to match(/-h #{params[:hostname]} #{Regexp.escape params[:image]}/)
    end

    it 'executes the provided command' do
      expect(cmd_executed).to match(/#{Regexp.escape params[:image]} #{Regexp.escape params[:cmd].join(' ')}/)
    end
  end

  describe '#create windows' do
    let(:params) { {
      image:      'jimi/hendrix:eletric-ladyland',
      cmd:        ['play', 'voodoo-chile'],
      ports:      '8080:80',
      volumes:    'C:/Users/BobDylan/AllAlong:/The/Watchtower',
      detach:     true,
      links:      [[:janis, 'joplin'], [:janis, 'janis']],
      env:        {key: 'value'},
      name:       cid,
      hostname:   'jimi-hendrix',
      privileged: true
    } }

    let(:translated_path) { "//c/Users/BobDylan/AllAlong:/The/Watchtower" }

    before do
      allow(Vagrant::Util::Platform).to receive(:windows?).and_return(true)
      subject.create(params)
    end

    it 'shares folders' do
      expect(cmd_executed).to match(/-v #{translated_path} .+ #{Regexp.escape params[:image]}/)
    end
  end


  describe '#created?' do
    let(:result) { subject.created?(cid) }

    it 'performs the check on all containers list' do
      subject.created?(cid)
      expect(cmd_executed).to match(/docker ps \-a \-q/)
    end

    context 'when container exists' do
      let(:stdout) { "foo\n#{cid}\nbar" }

      it { expect(result).to be_truthy }
    end

    context 'when container does not exist' do
      let(:stdout) { "foo\n#{cid}extra\nbar" }

      it { expect(result).to be_falsey }
    end
  end

  describe '#image?' do
    let(:result) { subject.image?(cid) }

    it 'performs the check on all images list' do
      subject.image?(cid)
      expect(cmd_executed).to match(/docker images \-q \--no-trunc/)
    end

    context 'when image id exists' do
      let(:stdout) { "foo\n#{cid}\nbar" }

      it { expect(result).to be_truthy }
    end

    context 'when sha265 image id exists' do
      let(:stdout) { "sha256:foo\nsha256:#{cid}\nsha256:bar" }

      it { expect(result).to be_truthy }
    end

    context 'when image does not exist' do
      let(:stdout) { "foo\n#{cid}extra\nbar" }

      it { expect(result).to be_falsey }
    end
  end


  describe '#pull' do
    it 'should pull images' do
      subject.pull('foo')
      expect(cmd_executed).to match(/docker pull foo/)
    end
  end

  describe '#read_used_ports' do
    let(:all_containers) { ["container1\ncontainer2"] }
    let(:container_info) { {"Name"=>"/container", "State"=>{"Running"=>true}, "HostConfig"=>{"PortBindings"=>{}}} }
    let(:empty_used_ports) { {} }

    context "with existing port forwards" do
      let(:container_info) { {"Name"=>"/container","State"=>{"Running"=>true}, "HostConfig"=>{"PortBindings"=>{"22/tcp"=>[{"HostIp"=>"127.0.0.1","HostPort"=>"2222"}] }}} }
      let(:used_ports_set) { {"2222"=>Set["127.0.0.1"]} }

      context "with active containers" do
        it 'should read all port bindings and return a hash of sets' do
          allow(subject).to receive(:all_containers).and_return(all_containers)
          allow(subject).to receive(:inspect_container).and_return(container_info)

          used_ports = subject.read_used_ports
          expect(used_ports).to eq(used_ports_set)
        end
      end

      context "with inactive containers" do
        let(:container_info) { {"Name"=>"/container", "State"=>{"Running"=>false}, "HostConfig"=>{"PortBindings"=>{"22/tcp"=>[{"HostIp"=>"127.0.0.1","HostPort"=>"2222"}] }}} }

        it 'returns empty' do
          allow(subject).to receive(:all_containers).and_return(all_containers)
          allow(subject).to receive(:inspect_container).and_return(container_info)

          used_ports = subject.read_used_ports
          expect(used_ports).to eq(empty_used_ports)
        end
      end
    end

    it 'returns empty if no ports are already bound' do
      allow(subject).to receive(:all_containers).and_return(all_containers)
      allow(subject).to receive(:inspect_container).and_return(container_info)

      used_ports = subject.read_used_ports
      expect(used_ports).to eq(empty_used_ports)
    end
  end

  describe '#running?' do
    let(:result) { subject.running?(cid) }

    it 'performs the check on the running containers list' do
      subject.running?(cid)
      expect(cmd_executed).to match(/docker ps \-q/)
      expect(cmd_executed).to_not include('-a')
    end

    context 'when container exists' do
      let(:stdout) { "foo\n#{cid}\nbar" }
      it { expect(result).to be_truthy }
    end

    context 'when container does not exist' do
      let(:stdout) { "foo\n#{cid}extra\nbar" }
      it { expect(result).to be_falsey }
    end
  end

  describe '#privileged?' do
    it 'identifies privileged containers' do
      allow(subject).to receive(:inspect_container).and_return({'HostConfig' => {"Privileged" => true}})
      expect(subject).to be_privileged(cid)
    end

    it 'identifies unprivileged containers' do
      allow(subject).to receive(:inspect_container).and_return({'HostConfig' => {"Privileged" => false}})
      expect(subject).to_not be_privileged(cid)
    end
  end

  describe '#start' do
    context 'when container is running' do
      before { allow(subject).to receive(:running?).and_return(true) }

      it 'does not start the container' do
        subject.start(cid)
        expect(cmd_executed).to be_nil
      end
    end

    context 'when container is not running' do
      before { allow(subject).to receive(:running?).and_return(false) }

      it 'starts the container' do
        subject.start(cid)
        expect(cmd_executed).to eq("docker start #{cid}")
      end
    end
  end

  describe '#stop' do
    context 'when container is running' do
      before { allow(subject).to receive(:running?).and_return(true) }

      it 'stops the container' do
        subject.stop(cid, 1)
        expect(cmd_executed).to eq("docker stop -t 1 #{cid}")
      end

      it "stops the container with the set timeout" do
        subject.stop(cid, 5)
        expect(cmd_executed).to eq("docker stop -t 5 #{cid}")
      end
    end

    context 'when container is not running' do
      before { allow(subject).to receive(:running?).and_return(false) }

      it 'does not stop container' do
        subject.stop(cid, 1)
        expect(cmd_executed).to be_nil
      end
    end
  end

  describe '#rm' do
    context 'when container has been created' do
      before { allow(subject).to receive(:created?).and_return(true) }

      it 'removes the container' do
        subject.rm(cid)
        expect(cmd_executed).to eq("docker rm -f -v #{cid}")
      end
    end

    context 'when container has not been created' do
      before { allow(subject).to receive(:created?).and_return(false) }

      it 'does not attempt to remove the container' do
        subject.rm(cid)
        expect(cmd_executed).to be_nil
      end
    end
  end

  describe '#rmi' do
    let(:id) { 'asdg21ew' }

    context 'image exists' do
      it "removes the image" do
        subject.rmi(id)
        expect(cmd_executed).to eq("docker rmi #{id}")
      end
    end

    context 'image is being used by running container' do
      before { allow(subject).to receive(:execute).and_raise("image is being used by running container") }

      it 'does not remove the image' do
        expect(subject.rmi(id)).to eq(false)
        subject.rmi(id)
      end
    end

    context 'image is being used by stopped container' do
      before { allow(subject).to receive(:execute).and_raise("image is being used by stopped container") }

      it 'does not remove the image' do
        expect(subject.rmi(id)).to eq(false)
        subject.rmi(id)
      end
    end

    context 'container is using it' do
      before { allow(subject).to receive(:execute).and_raise("container is using it") }

      it 'does not remove the image' do
        expect(subject.rmi(id)).to eq(false)
        subject.rmi(id)
      end
    end

    context 'image does not exist' do
      before { allow(subject).to receive(:execute).and_raise("No such image") }

      it 'raises an error' do
        expect(subject.rmi(id)).to eq(nil)
        subject.rmi(id)
      end
    end
  end

  describe '#inspect_container' do
    let(:stdout) { '[{"json": "value"}]' }

    it 'inspects the container' do
      subject.inspect_container(cid)
      expect(cmd_executed).to eq("docker inspect #{cid}")
    end

    it 'parses the json output' do
      expect(subject.inspect_container(cid)).to eq('json' => 'value')
    end
  end

  describe '#all_containers' do
    let(:stdout) { "container1\ncontainer2" }

    it 'returns an array of all known containers' do
      expect(subject.all_containers).to eq(['container1', 'container2'])
      expect(cmd_executed).to eq("docker ps -a -q --no-trunc")
    end
  end

  describe '#docker_bridge_ip' do
    context 'from docker network command' do 
    let(:network_struct) {
    [{
        "Name": "bridge",
        "Id": "ae74f6cc18bbcde86326937797070b814cc71bfc4a6d8e3e8cf3b2cc5c7f4a7d",
        "Created": "2019-03-20T14:10:06.313314662-07:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": nil,
            "Config": [
                {
                    "Subnet": "172.17.0.0/16",
                    "Gateway": "172.17.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "a1ee9b12bcea8268495b1f43e8d1285df1925b7174a695075f6140adb9415d87": {
                "Name": "vagrant-sandbox_docker-1_1553116237",
                "EndpointID": "fc1b0ed6e4f700cf88bb26a98a0722655191542e90df3e3492461f4d1f3c0cae",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.bridge.default_bridge": "true",
            "com.docker.network.bridge.enable_icc": "true",
            "com.docker.network.bridge.enable_ip_masquerade": "true",
            "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
            "com.docker.network.bridge.name": "docker0",
            "com.docker.network.driver.mtu": "1500"
        },
        "Labels": {}
    }].to_json
    }
      it "returns the bridge gateway ip" do
        allow(subject).to receive(:inspect_network).and_return(JSON.load(network_struct))
        expect(subject.docker_bridge_ip).to eq('172.17.0.1')
      end
    end

    context 'when falling back to ip' do
      let(:stdout) { " inet 123.456.789.012/16 " }

      it 'returns the bridge ip' do
        expect(subject.docker_bridge_ip).to eq('123.456.789.012')
        expect(cmd_executed).to eq("ip -4 addr show scope global docker0")
      end
    end
  end

  describe '#docker_connect_network' do
    let(:opts) { ["--ip", "172.20.128.2"] }

    it 'connects a network to a container' do
      subject.connect_network("vagrant_network", cid, opts)
      expect(cmd_executed).to eq("docker network connect vagrant_network #{cid} --ip 172.20.128.2")
    end
  end

  describe '#docker_create_network' do
    let(:opts) { ["--subnet", "172.20.0.0/16"] }

    it 'creates a network' do
      subject.create_network("vagrant_network", opts)
      expect(cmd_executed).to eq("docker network create vagrant_network --subnet 172.20.0.0/16")
    end
  end

  describe '#docker_disconnet_network' do
    it 'disconnects a network from a container' do
      subject.disconnect_network("vagrant_network", cid)
      expect(cmd_executed).to eq("docker network disconnect vagrant_network #{cid} --force")
    end
  end

  describe '#docker_inspect_network' do
    it 'gets info about a network' do
      subject.inspect_network("vagrant_network")
      expect(cmd_executed).to eq("docker network inspect vagrant_network")
    end
  end

  describe '#docker_list_network' do
    it 'lists docker networks' do
      subject.list_network()
      expect(cmd_executed).to eq("docker network ls")
    end
  end

  describe '#docker_rm_network' do
    it 'deletes a docker network' do
      subject.rm_network("vagrant_network")
      expect(cmd_executed).to eq("docker network rm vagrant_network")
    end
  end

  describe '#network_defined?' do
    let(:subnet_string) { "172.20.0.0/16" }
    let(:network_names) { ["vagrant_network_172.20.0.0/16", "bridge", "null" ] }

    before do
      allow(subject).to receive(:list_network_names).and_return(network_names)
      allow(subject).to receive(:inspect_network).and_return(JSON.load(docker_network_struct))
    end

    it "returns network name if defined" do
      network_name = subject.network_defined?(subnet_string)
      expect(network_name).to eq("vagrant_network_172.20.0.0/16")
    end

    it "returns nil name if not defined" do
      network_name = subject.network_defined?("120.20.0.0/24")
      expect(network_name).to eq(nil)
    end

    context "when config information is missing" do
      let(:docker_network_struct) do
        [
          {
            "Name": "bridge",
            "Id": "ae74f6cc18bbcde86326937797070b814cc71bfc4a6d8e3e8cf3b2cc5c7f4a7d",
            "Created": "2019-03-20T14:10:06.313314662-07:00",
            "Scope": "local",
            "Driver": "bridge",
            "EnableIPv6": false,
            "IPAM": {
              "Driver": "default",
              "Options": nil,
            },
            "Internal": false,
            "Attachable": false,
            "Ingress": false,
            "ConfigFrom": {
              "Network": ""
            },
            "ConfigOnly": false,
            "Containers": {
              "a1ee9b12bcea8268495b1f43e8d1285df1925b7174a695075f6140adb9415d87": {
                "Name": "vagrant-sandbox_docker-1_1553116237",
                "EndpointID": "fc1b0ed6e4f700cf88bb26a98a0722655191542e90df3e3492461f4d1f3c0cae",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
              },
              "Options": {
                "com.docker.network.bridge.default_bridge": "true",
                "com.docker.network.bridge.enable_icc": "true",
                "com.docker.network.bridge.enable_ip_masquerade": "true",
                "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
                "com.docker.network.bridge.name": "docker0",
                "com.docker.network.driver.mtu": "1500"
              },
              "Labels": {}
            },
          }
        ].to_json
      end

      it "should not raise an error" do
        expect { subject.network_defined?(subnet_string) }.not_to raise_error
      end
    end

    context "when IPAM information is missing" do
      let(:docker_network_struct) do
        [
          {
            "Name": "bridge",
            "Id": "ae74f6cc18bbcde86326937797070b814cc71bfc4a6d8e3e8cf3b2cc5c7f4a7d",
            "Created": "2019-03-20T14:10:06.313314662-07:00",
            "Scope": "local",
            "Driver": "bridge",
            "EnableIPv6": false,
            "Internal": false,
            "Attachable": false,
            "Ingress": false,
            "ConfigFrom": {
              "Network": ""
            },
            "ConfigOnly": false,
            "Containers": {
              "a1ee9b12bcea8268495b1f43e8d1285df1925b7174a695075f6140adb9415d87": {
                "Name": "vagrant-sandbox_docker-1_1553116237",
                "EndpointID": "fc1b0ed6e4f700cf88bb26a98a0722655191542e90df3e3492461f4d1f3c0cae",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
              },
              "Options": {
                "com.docker.network.bridge.default_bridge": "true",
                "com.docker.network.bridge.enable_icc": "true",
                "com.docker.network.bridge.enable_ip_masquerade": "true",
                "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
                "com.docker.network.bridge.name": "docker0",
                "com.docker.network.driver.mtu": "1500"
              },
              "Labels": {}
            },
          }
        ].to_json
      end

      it "should not raise an error" do
        expect { subject.network_defined?(subnet_string) }.not_to raise_error
      end
    end
  end

  describe '#network_containing_address' do
    let(:address) { "172.20.128.2" }
    let(:network_names) { ["vagrant_network_172.20.0.0/16", "bridge", "null" ] }

    it "returns the network name if it contains the requested address" do
      allow(subject).to receive(:list_network_names).and_return(network_names)
      allow(subject).to receive(:inspect_network).and_return(JSON.load(docker_network_struct))

      network_name = subject.network_containing_address(address)
      expect(network_name).to eq("vagrant_network_172.20.0.0/16")
    end

    it "returns nil if no networks contain the requested address" do
      allow(subject).to receive(:list_network_names).and_return(network_names)
      allow(subject).to receive(:inspect_network).and_return(JSON.load(docker_network_struct))

      network_name = subject.network_containing_address("127.0.0.1")
      expect(network_name).to eq(nil)
    end
  end

  describe '#existing_named_network?' do
    let(:network_names) { ["vagrant_network_172.20.0.0/16", "bridge", "null" ] }

    it "returns true if the network exists" do
      allow(subject).to receive(:list_network_names).and_return(network_names)

      expect(subject.existing_named_network?("vagrant_network_172.20.0.0/16")).to be_truthy
    end

    it "returns false if the network does not exist" do
      allow(subject).to receive(:list_network_names).and_return(network_names)

      expect(subject.existing_named_network?("vagrant_network_17.0.0/16")).to be_falsey
    end
  end

  describe '#list_network_names' do
    let(:unparsed_network_names) { "vagrant_network_172.20.0.0/16\nbridge\nnull" }
    let(:network_names) { ["vagrant_network_172.20.0.0/16", "bridge", "null" ] }

    it "lists the network names" do
      allow(subject).to receive(:list_network).with("--format={{.Name}}").
        and_return(unparsed_network_names)

      expect(subject.list_network_names).to eq(network_names)
    end
  end

  describe '#network_used?' do
    let(:network_name) { "vagrant_network_172.20.0.0/16" }
    it "returns nil if no networks" do
      allow(subject).to receive(:inspect_network).with(network_name).and_return(nil)

      expect(subject.network_used?(network_name)).to eq(nil)
    end

    it "returns true if network has containers in use" do
      allow(subject).to receive(:inspect_network).with(network_name).and_return([JSON.load(docker_network_struct).last])

      expect(subject.network_used?(network_name)).to be_truthy
    end

    it "returns false if network has containers in use" do
      allow(subject).to receive(:inspect_network).with("host").and_return([JSON.load(docker_network_struct)[1]])

      expect(subject.network_used?("host")).to be_falsey
    end
  end
end
