require_relative "../../../base"
require "fake_ftp"

require Vagrant.source_root.join("plugins/pushes/ftp/push")

describe VagrantPlugins::FTPPush::Push do
  include_context "unit"

  let(:env) { isolated_environment }
  let(:config) do
    double("config",
      host:        "127.0.0.1:#{@port}",
      username:    "sethvargo",
      password:    "bacon",
      passive:     false,
      secure:      false,
      destination: "/var/www/site",
    )
  end
  let(:ui) do
    double("ui",
      info: nil,
    )
  end

  subject { described_class.new(env, config) }

  before do
    allow(env).to receive(:root_path)
      .and_return(File.expand_path("..", __FILE__))
    allow(env).to receive(:ui)
      .and_return(ui)
  end

  describe "#push" do
    before(:all) do
      @server = nil
      with_random_port do |port1, port2|
        @port = port1
        @server = FakeFtp::Server.new(port1, port2)
      end
      @server.start

      @dir = Dir.mktmpdir("vagrant-ftp-push")
      FileUtils.touch("#{@dir}/.hidden.rb")
      FileUtils.touch("#{@dir}/application.rb")
      FileUtils.touch("#{@dir}/config.rb")
      FileUtils.touch("#{@dir}/Gemfile")
      FileUtils.touch("#{@dir}/data.txt")
      FileUtils.mkdir("#{@dir}/empty_folder")
    end

    after(:all) do
      FileUtils.rm_rf(@dir)
      @server.stop
    end

    let(:server) { @server }

    before do
      allow(config).to receive(:dir)
        .and_return(@dir)

      allow(config).to receive(:includes)
        .and_return([])

      allow(config).to receive(:excludes)
        .and_return(%w(*.rb))
    end


    it "pushes the files to the server" do
      subject.push
      expect(server.files).to eq(%w(Gemfile data.txt))
    end
  end

  describe "#connect" do
    before do
      allow_any_instance_of(VagrantPlugins::FTPPush::FTPAdapter)
        .to receive(:connect)
        .and_yield(:ftp)
      allow_any_instance_of(VagrantPlugins::FTPPush::SFTPAdapter)
        .to receive(:connect)
        .and_yield(:sftp)
    end

    context "when secure is requested" do
      before do
        allow(config).to receive(:secure)
          .and_return(true)
      end

      it "yields a new SFTPAdapter" do
        expect { |b| subject.connect(&b) }.to yield_with_args(:sftp)
      end
    end

    context "when secure is not requested" do
      before do
        allow(config).to receive(:secure)
          .and_return(false)
      end

      it "yields a new FTPAdapter" do
        expect { |b| subject.connect(&b) }.to yield_with_args(:ftp)
      end
    end
  end

  describe "#all_files" do
    before(:all) do
      @dir = Dir.mktmpdir("vagrant-ftp-push-push-all-files")

      FileUtils.touch("#{@dir}/.hidden.rb")
      FileUtils.touch("#{@dir}/application.rb")
      FileUtils.touch("#{@dir}/config.rb")
      FileUtils.touch("#{@dir}/Gemfile")
      FileUtils.mkdir("#{@dir}/empty_folder")
      FileUtils.mkdir("#{@dir}/folder")
      FileUtils.mkdir("#{@dir}/folder/.git")
      FileUtils.touch("#{@dir}/folder/.git/config")
      FileUtils.touch("#{@dir}/folder/server.rb")
    end

    after(:all) do
      FileUtils.rm_rf(@dir)
    end

    let(:files) do
      subject.all_files.map do |file|
        file.sub("#{@dir}/", "")
      end
    end

    before do
      allow(config).to receive(:dir)
        .and_return(@dir)

      allow(config).to receive(:includes)
        .and_return(%w(not_a_file.rb still_not_a_file.rb))

      allow(config).to receive(:excludes)
        .and_return(%w(*.rb))
    end

    it "returns the list of real files + includes, without excludes" do
      expect(files).to eq(%w(
        Gemfile
        folder/.git/config
      ))
    end
  end

  describe "#includes_files" do
    before(:all) do
      @dir = Dir.mktmpdir("vagrant-ftp-push-includes-files")

      FileUtils.touch("#{@dir}/.hidden.rb")
      FileUtils.touch("#{@dir}/application.rb")
      FileUtils.touch("#{@dir}/config.rb")
      FileUtils.touch("#{@dir}/Gemfile")
      FileUtils.mkdir("#{@dir}/folder")
      FileUtils.mkdir("#{@dir}/folder/.git")
      FileUtils.touch("#{@dir}/folder/.git/config")
      FileUtils.touch("#{@dir}/folder/server.rb")
    end

    after(:all) do
      FileUtils.rm_rf(@dir)
    end

    let(:files) do
      subject.includes_files.map do |file|
        file.sub("#{@dir}/", "")
      end
    end

    before do
      allow(config).to receive(:dir)
        .and_return(@dir)
    end

    def set_includes(value)
      allow(config).to receive(:includes)
        .and_return(value)
    end

    it "includes the file" do
      set_includes(["Gemfile"])
      expect(files).to eq(%w(
        Gemfile
      ))
    end

    it "includes the files that are subdirectories" do
      set_includes(["folder"])
      expect(files).to eq(%w(
        folder
        folder/.git
        folder/.git/config
        folder/server.rb
      ))
    end

    it "includes files that match a pattern" do
      set_includes(["*.rb"])
      expect(files).to eq(%w(
        .hidden.rb
        application.rb
        config.rb
      ))
    end
  end

  describe "#filter_excludes" do
    let(:dir) { "/root/dir" }

    let(:list) do
      %W(
        #{dir}/.hidden.rb
        #{dir}/application.rb
        #{dir}/config.rb
        #{dir}/Gemfile
        #{dir}/folder
        #{dir}/folder/.git
        #{dir}/folder/.git/config
        #{dir}/folder/server.rb

        /path/outside/you.rb
        /path/outside/me.rb
        /path/outside/folder/bacon.rb
      )
    end

    before do
      allow(config).to receive(:dir)
        .and_return(dir)
    end

    it "excludes files" do
      subject.filter_excludes!(list, %w(*.rb))

      expect(list).to eq(%W(
        #{dir}/Gemfile
        #{dir}/folder
        #{dir}/folder/.git
        #{dir}/folder/.git/config
      ))
    end

    it "excludes files in a directory" do
      subject.filter_excludes!(list, %w(folder))

      expect(list).to eq(%W(
        #{dir}/.hidden.rb
        #{dir}/application.rb
        #{dir}/config.rb
        #{dir}/Gemfile

        /path/outside/you.rb
        /path/outside/me.rb
        /path/outside/folder/bacon.rb
      ))
    end

    it "excludes specific files in a directory" do
      subject.filter_excludes!(list, %w(/path/outside/folder/*.rb))

      expect(list).to eq(%W(
        #{dir}/.hidden.rb
        #{dir}/application.rb
        #{dir}/config.rb
        #{dir}/Gemfile
        #{dir}/folder
        #{dir}/folder/.git
        #{dir}/folder/.git/config
        #{dir}/folder/server.rb

        /path/outside/you.rb
        /path/outside/me.rb
      ))
    end

    it "excludes files outside the #dir" do
      subject.filter_excludes!(list, %w(/path/outside))

      expect(list).to eq(%W(
        #{dir}/.hidden.rb
        #{dir}/application.rb
        #{dir}/config.rb
        #{dir}/Gemfile
        #{dir}/folder
        #{dir}/folder/.git
        #{dir}/folder/.git/config
        #{dir}/folder/server.rb
      ))
    end
  end
end
