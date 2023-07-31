# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "tmpdir"
require_relative "../base"

require "vagrant/bundler"

describe Vagrant::Bundler::SolutionFile do
  let(:plugin_path) { Pathname.new(tmpdir) + "plugin_file" }
  let(:solution_path) { Pathname.new(tmpdir) + "solution_file" }
  let(:tmpdir) { @tmpdir ||= Dir.mktmpdir("vagrant-bundler-test") }
  let(:subject) {
    described_class.new(
      plugin_file: plugin_path,
      solution_file: solution_path
    )
  }

  after do
    if @tmpdir
      FileUtils.rm_rf(@tmpdir)
      @tmpdir = nil
    end
  end

  describe "#initialize" do
    context "file paths" do
      context "with solution_file not provided" do
        let(:subject) { described_class.new(plugin_file: plugin_path) }

        it "should set the plugin_file" do
          expect(subject.plugin_file.to_s).to eq(plugin_path.to_s)
        end

        it "should set solution path to same directory" do
          expect(subject.solution_file.to_s).to eq(plugin_path.to_s + ".sol")
        end
      end

      context "with custom solution_file provided" do
        let(:subject) { described_class.
            new(plugin_file: plugin_path, solution_file: solution_path) }

        it "should set the plugin file path" do
          expect(subject.plugin_file.to_s).to eq(plugin_path.to_s)
        end

        it "should set the solution file path to given value" do
          expect(subject.solution_file.to_s).to eq(solution_path.to_s)
        end
      end
    end

    context "initialization behavior" do
      context "on creation" do
        before { expect_any_instance_of(described_class).to receive(:load) }

        it "should load solution file during initialization" do
          subject
        end
      end

      it "should be invalid by default" do
        expect(subject.valid?).to be_falsey
      end
    end
  end

  describe "#dependency_list=" do
    it "should accept a list of Gem::Dependency instances" do
      list = ["dep1", "dep2"].map{ |x| Gem::Dependency.new(x) }
      subject.dependency_list = list
      expect(subject.dependency_list.map(&:dependency)).to eq(list)
    end

    it "should error if list includes instance not Gem::Dependency" do
      list = ["dep1", "dep2"].map{ |x| Gem::Dependency.new(x) } << :invalid
      expect{ subject.dependency_list = list }.to raise_error(TypeError)
    end

    it "should convert list into resolver dependency request" do
      list = ["dep1", "dep2"].map{ |x| Gem::Dependency.new(x) }
      subject.dependency_list = list
      subject.dependency_list.each do |dep|
        expect(dep).to be_a(Gem::Resolver::DependencyRequest)
      end
    end

    it "should freeze the new dependency list" do
      list = ["dep1", "dep2"].map{ |x| Gem::Dependency.new(x) }
      subject.dependency_list = list
      expect(subject.dependency_list).to be_frozen
    end
  end

  describe "#delete!" do
    context "when file does not exist" do
      before { subject.solution_file.delete if subject.solution_file.exist? }

      it "should return false" do
        expect(subject.delete!).to be_falsey
      end

      it "should not exist" do
        subject.delete!
        expect(subject.solution_file.exist?).to be_falsey
      end
    end

    context "when file does exist" do
      before { subject.solution_file.write('x') }

      it "should return true" do
        expect(subject.delete!).to be_truthy
      end

      it "should not exist" do
        expect(subject.solution_file.exist?).to be_truthy
        subject.delete!
        expect(subject.solution_file.exist?).to be_falsey
      end
    end
  end

  describe "store!" do
    context "when plugin file does not exist" do
      before { subject.plugin_file.delete if subject.plugin_file.exist? }

      it "should return false" do
        expect(subject.store!).to be_falsey
      end

      it "should not create a solution file" do
        subject.store!
        expect(subject.solution_file.exist?).to be_falsey
      end
    end

    context "when plugin file does exist" do
      before { subject.plugin_file.write("x") }

      it "should return true" do
        expect(subject.store!).to be_truthy
      end

      it "should create a solution file" do
        expect(subject.solution_file.exist?).to be_falsey
        subject.store!
        expect(subject.solution_file.exist?).to be_truthy
      end

      context "stored file" do
        let(:content) {
          @content ||= JSON.load(subject.solution_file.read)
        }
        before { subject.store! }
        after { @content = nil }

        it "should store JSON hash" do
          expect(content).to be_a(Hash)
        end

        it "should include dependencies key as array value" do
          expect(content["dependencies"]).to be_a(Array)
        end

        it "should include checksum key as string value" do
          expect(content["checksum"]).to be_a(String)
        end

        it "should include vagrant_version key as string value" do
          expect(content["vagrant_version"]).to be_a(String)
        end

        it "should include vagrant_version key that matches current version" do
          expect(content["vagrant_version"]).to eq(Vagrant::VERSION)
        end
      end
    end
  end

  describe "behavior" do
    context "when storing new solution set" do
      let(:deps) { ["dep1", "dep2"].map{ |n| Gem::Dependency.new(n) } }

      context "when plugin file does not exist" do
        before { subject.solution_file.delete if subject.solution_file.exist? }

        it "should not create a solution file" do
          subject.dependency_list = deps
          subject.store!
          expect(subject.solution_file.exist?).to be_falsey
        end
      end

      context "when plugin file does exist" do
        before { subject.plugin_file.write("x") }

        it "should create a solution file" do
          subject.dependency_list = deps
          subject.store!
          expect(subject.solution_file.exist?).to be_truthy
        end

        it "should update solution file instance to valid" do
          expect(subject.valid?).to be_falsey
          subject.dependency_list = deps
          subject.store!
          expect(subject.valid?).to be_truthy
        end

        context "when solution file does exist" do
          before do
            subject.dependency_list = deps
            subject.store!
          end

          it "should be a valid solution" do
            subject = described_class.new(
              plugin_file: plugin_path,
              solution_file: solution_path
            )
            expect(subject.valid?).to be_truthy
          end

          it "should have expected dependency list" do
            subject = described_class.new(
              plugin_file: plugin_path,
              solution_file: solution_path
            )
            expect(subject.dependency_list).to eq(deps)
          end

          context "when plugin file has been changed" do
            before { subject.plugin_file.write("xy") }

            it "should not be a valid solution" do
              subject = described_class.new(
                plugin_file: plugin_path,
                solution_file: solution_path
              )
              expect(subject.valid?).to be_falsey
            end

            it "should have empty dependency list" do
              subject = described_class.new(
                plugin_file: plugin_path,
                solution_file: solution_path
              )
              expect(subject.dependency_list).to be_empty
            end
          end
        end
      end
    end
  end

  describe "#load" do
    let(:plugin_file_exists) { false }
    let(:solution_file_exists) { false }
    let(:plugin_file_path) { "PLUGIN_FILE_PATH" }
    let(:solution_file_path) { "SOLUTION_FILE_PATH" }
    let(:plugin_file) { double("plugin-file") }
    let(:solution_file) { double("solution-file") }

    subject do
      described_class.new(plugin_file: plugin_file_path, solution_file: solution_file_path)
    end

    before do
      allow(Pathname).to receive(:new).with(plugin_file_path).and_return(plugin_file)
      allow(Pathname).to receive(:new).with(solution_file_path).and_return(solution_file)
      allow(plugin_file).to receive(:exist?).and_return(plugin_file_exists)
      allow(solution_file).to receive(:exist?).and_return(solution_file_exists)
    end

    context "when plugin file and solution file do not exist" do
      it "should not attempt to read the solution" do
        expect_any_instance_of(described_class).not_to receive(:read_solution)
        subject
      end
    end

    context "when plugin file exists and solution file does not" do
      let(:plugin_file_exists) { true }

      it "should not attempt to read the solution" do
        expect_any_instance_of(described_class).not_to receive(:read_solution)
        subject
      end
    end

    context "when solution file exists and plugin file does not" do
      let(:solution_file_exists) { true }

      it "should not attempt to read the solution" do
        expect_any_instance_of(described_class).not_to receive(:read_solution)
        subject
      end
    end

    context "when solution file and plugin file exist" do
      let(:plugin_file_exists) { true }
      let(:solution_file_exists) { true }

      let(:solution_file_contents) { "" }

      before do
        allow(solution_file).to receive(:read).and_return(solution_file_contents)
        allow_any_instance_of(described_class).to receive(:plugin_file_checksum).and_return("VALID")
      end

      context "when solution file is empty" do
        it "should return false" do
          expect(subject.send(:load)).to be_falsey
        end
      end

      context "when solution file contains invalid checksum" do
        let(:solution_file_contents) { {checksum: "INVALID", vagrant_version: Vagrant::VERSION}.to_json }

        it "should return false" do
          expect(subject.send(:load)).to be_falsey
        end
      end

      context "when solution file contains different Vagrant version" do
        let(:solution_file_contents) { {checksum: "VALID", vagrant_version: "0.1"}.to_json }

        it "should return false" do
          expect(subject.send(:load)).to be_falsey
        end
      end

      context "when solution file contains valid Vagrant version and valid checksum" do
        let(:solution_file_contents) {
          {checksum: "VALID", vagrant_version: Vagrant::VERSION, dependencies: file_dependencies}.to_json
        }
        let(:file_dependencies) { dependency_list.map{|d| [d.name, d.requirements_list]} }
        let(:dependency_list) { [] }

        it "should return true" do
          expect(subject.send(:load)).to be_truthy
        end

        it "should be valid" do
          expect(subject).to be_valid
        end

        context "when solution file contains dependency list" do
          let(:dependency_list) { [
            Gem::Dependency.new("dep1", "> 0"),
            Gem::Dependency.new("dep2", "< 3")
          ] }

          it "should be valid" do
            expect(subject).to be_valid
          end

          it "should convert list into dependency requests" do
            subject.dependency_list.each do |d|
              expect(d).to be_a(Gem::Resolver::DependencyRequest)
            end
          end

          it "should include defined dependencies" do
            expect(subject.dependency_list.first).to eq(dependency_list.first)
            expect(subject.dependency_list.last).to eq(dependency_list.last)
          end

          it "should freeze the dependency list" do
            expect(subject.dependency_list).to be_frozen
          end
        end
      end
    end
  end

  describe "#read_solution" do
    let(:solution_file_contents) { "" }
    let(:plugin_file_path) { "PLUGIN_FILE_PATH" }
    let(:solution_file_path) { "SOLUTION_FILE_PATH" }
    let(:plugin_file) { double("plugin-file") }
    let(:solution_file) { double("solution-file") }

    subject do
      described_class.new(plugin_file: plugin_file_path, solution_file: solution_file_path)
    end

    before do
      allow(Pathname).to receive(:new).with(plugin_file_path).and_return(plugin_file)
      allow(Pathname).to receive(:new).with(solution_file_path).and_return(solution_file)
      allow(plugin_file).to receive(:exist?).and_return(false)
      allow(solution_file).to receive(:exist?).and_return(false)
      allow(solution_file).to receive(:read).and_return(solution_file_contents)
    end

    it "should return nil when file contents are empty" do
      expect(subject.send(:read_solution)).to be_nil
    end

    context "when file contents are hash" do
      let(:solution_file_contents) { {checksum: "VALID"}.to_json }

      it "should return a hash" do
        expect(subject.send(:read_solution)).to be_a(Hash)
      end

      it "should return a hash with indifferent access" do
        expect(subject.send(:read_solution)).to be_a(Vagrant::Util::HashWithIndifferentAccess)
      end
    end

    context "when file contents are array" do
      let(:solution_file_contents) { ["test"].to_json }

      it "should return a hash" do
        expect(subject.send(:read_solution)).to be_a(Hash)
      end

      it "should return a hash with indifferent access" do
        expect(subject.send(:read_solution)).to be_a(Vagrant::Util::HashWithIndifferentAccess)
      end
    end

    context "when file contents are null" do
      let(:solution_file_contents) { "null" }

      it "should return nil" do
        expect(subject.send(:read_solution)).to be_nil
      end
    end

    context "when file contents are invalid" do
      let(:solution_file_contents) { "{2dfwef" }

      it "should return nil" do
        expect(subject.send(:read_solution)).to be_nil
      end
    end
  end
end

describe Vagrant::Bundler do
  include_context "unit"

  let(:iso_env) { isolated_environment }
  let(:env) { iso_env.create_vagrant_env }
  let(:tmpdir) { @v_tmpdir ||= Pathname.new(Dir.mktmpdir("vagrant-bundler-test")) }

  before do
    @tmpdir = Dir.mktmpdir("vagrant-bundler-test")
    @vh = ENV["VAGRANT_HOME"]
    ENV["VAGRANT_HOME"] = @tmpdir
  end

  after do
    ENV["VAGRANT_HOME"] = @vh
    FileUtils.rm_rf(@tmpdir)
    FileUtils.rm_rf(@v_tmpdir) if @v_tmpdir
  end

  it "should isolate gem path based on Ruby version" do
    expect(subject.plugin_gem_path.to_s).to end_with(RUBY_VERSION)
  end

  it "should not have an env_plugin_gem_path by default" do
    expect(subject.env_plugin_gem_path).to be_nil
  end

  describe "#initialize" do
    it "should automatically set the plugin gem path" do
      expect(subject.plugin_gem_path).not_to be_nil
    end

    it "should add current ruby version to plugin gem path suffix" do
      expect(subject.plugin_gem_path.to_s).to end_with(RUBY_VERSION)
    end

    it "should freeze the plugin gem path" do
      expect(subject.plugin_gem_path).to be_frozen
    end
  end

  describe "#environment_path=" do
    it "should error if not given Pathname" do
      expect { subject.environment_path = :value }.
        to raise_error(TypeError)
    end

    context "when set with Pathname" do
      let(:env_path) { Pathname.new("/dev/null") }
      before { subject.environment_path = env_path }

      it "should set the environment_data_path" do
        expect(subject.environment_data_path).to eq(env_path)
      end

      it "should set the env_plugin_gem_path" do
        expect(subject.env_plugin_gem_path).not_to be_nil
      end

      it "should suffix current ruby version to env_plugin_gem_path" do
        expect(subject.env_plugin_gem_path.to_s).to end_with(RUBY_VERSION)
      end

      it "should base env_plugin_gem_path on environment_path value" do
        expect(subject.env_plugin_gem_path.to_s).to start_with(env_path.to_s)
      end

      it "should freeze the env_plugin_gem_path" do
        expect(subject.env_plugin_gem_path).to be_frozen
      end
    end
  end

  describe "#load_solution_file" do
    let(:local_opt) { nil }
    let(:global_opt) { nil }
    let(:options) { {local: local_opt, global: global_opt} }

    it "should return nil when local and global options are blank" do
      expect(subject.load_solution_file(options)).to be_nil
    end

    context "when environment data path is set" do
      let(:env_path) { "/dev/null" }
      before { subject.environment_path = Pathname.new(env_path) }

      context "when local option is set" do
        let(:local_opt) { tmpdir + "local" }

        it "should return a SolutionFile instance" do
          expect(subject.load_solution_file(options)).to be_a(Vagrant::Bundler::SolutionFile)
        end

        it "should be located in the environment data path" do
          file = subject.load_solution_file(options)
          expect(file.solution_file.to_s).to start_with(env_path)
        end

        it "should have a local.sol solution file" do
          file = subject.load_solution_file(options)
          expect(file.solution_file.to_s).to end_with("local.sol")
        end

        it "should have plugin file set to local value" do
          file = subject.load_solution_file(options)
          expect(file.plugin_file.to_s).to eq(local_opt.to_s)
        end
      end

      context "when global option is set" do
        let(:global_opt) { tmpdir + "global" }

        it "should return a SolutionFile instance" do
          expect(subject.load_solution_file(options)).to be_a(Vagrant::Bundler::SolutionFile)
        end

        it "should be located in the environment data path" do
          file = subject.load_solution_file(options)
          expect(file.solution_file.to_s).to start_with(env_path)
        end

        it "should have a global.sol solution file" do
          file = subject.load_solution_file(options)
          expect(file.solution_file.to_s).to end_with("global.sol")
        end

        it "should have plugin file set to global value" do
          file = subject.load_solution_file(options)
          expect(file.plugin_file.to_s).to eq(global_opt.to_s)
        end
      end

      context "when local and global option is set" do
        let(:global_opt) { tmpdir + "global" }
        let(:local_opt) { tmpdir + "local" }

        it "should return nil" do
          expect(subject.load_solution_file(options)).to be_nil
        end
      end
    end

    context "when environment data path is unset" do
      context "when local option is set" do
        let(:local_opt) { tmpdir + "local" }

        it "should return nil" do
          expect(subject.load_solution_file(options)).to be_nil
        end
      end

      context "when global option is set" do
        let(:global_opt) { tmpdir + "global" }

        it "should return a SolutionFile instance" do
          expect(subject.load_solution_file(options)).to be_a(Vagrant::Bundler::SolutionFile)
        end

        it "should be located in the vagrant user data path" do
          file = subject.load_solution_file(options)
          expect(file.solution_file.to_s).to start_with(Vagrant.user_data_path.to_s)
        end

        it "should have a global.sol solution file" do
          file = subject.load_solution_file(options)
          expect(file.solution_file.to_s).to end_with("global.sol")
        end

        it "should have plugin file set to global value" do
          file = subject.load_solution_file(options)
          expect(file.plugin_file.to_s).to eq(global_opt.to_s)
        end
      end
    end
  end

  describe "#deinit" do
    it "should provide method for backwards compatibility" do
      subject.deinit
    end
  end

  describe "DEFAULT_GEM_SOURCES" do
    it "should list hashicorp gemstore first" do
      expect(described_class.const_get(:DEFAULT_GEM_SOURCES).first).to eq(
        described_class.const_get(:HASHICORP_GEMSTORE))
    end
  end

  describe "#init!" do
    context "Gem.sources" do
      before {
        Gem.sources.clear
        Gem.sources << "https://rubygems.org/" }

      it "should add hashicorp gem store" do
        subject.init!([])
        expect(Gem.sources).to include(described_class.const_get(:HASHICORP_GEMSTORE))
      end

      it "should add hashicorp gem store to start of sources list" do
        subject.init!([])
        expect(Gem.sources.sources.first.uri.to_s).to eq(described_class.const_get(:HASHICORP_GEMSTORE))
      end
    end

    context "multiple specs" do
      let(:solution_file) { double('solution_file') }
      let(:vagrant_set)   { double('vagrant_set') }

      before do
        allow(subject).to receive(:load_solution_file).and_return(solution_file)
        allow(subject).to receive(:generate_vagrant_set).and_return(vagrant_set)
        allow(solution_file).to receive(:valid?).and_return(true)
      end

      it "should activate spec of deps already loaded" do
        spec = Gem.loaded_specs.first
        deps = [spec[0]]
        specs = [spec[1].dup, spec[1].dup]
        specs[0].version = Gem::Version::new('0.0.1')
        # make sure haven't accidentally modified both
        expect(specs[0].version).to_not eq(specs[1].version)

        expect(solution_file).to receive(:dependency_list).and_return(deps)
        expect(vagrant_set).to receive(:find_all).and_return(specs)
        expect(subject).to receive(:activate_solution) do |activate_specs|
          expect(activate_specs.length()).to eq(1)
          expect(activate_specs[0].full_spec()).to eq(specs[1])
        end
        subject.init!([])
      end
    end
  end

  describe "#install" do
    let(:plugins){ {"my-plugin" => {"gem_version" => "> 0"}} }

    it "should pass plugin information hash to internal install" do
      expect(subject).to receive(:internal_install).with(plugins, any_args)
      subject.install(plugins)
    end

    it "should not include any update plugins" do
      expect(subject).to receive(:internal_install).with(anything, nil, any_args)
      subject.install(plugins)
    end

    it "should flag local when local is true" do
      expect(subject).to receive(:internal_install).with(any_args, env_local: true)
      subject.install(plugins, true)
    end

    it "should not flag local when local is not set" do
      expect(subject).to receive(:internal_install).with(any_args, env_local: false)
      subject.install(plugins)
    end
  end

  describe "#install_local" do
    let(:plugin_source){ double("plugin_source", spec: plugin_spec) }
    let(:plugin_spec){ double("plugin_spec", name: plugin_name, version: plugin_version) }
    let(:plugin_name){ "PLUGIN_NAME" }
    let(:plugin_version){ "1.0.0" }
    let(:plugin_path){ "PLUGIN_PATH" }
    let(:sources){ "SOURCES" }

    before do
      allow(Gem::Source::SpecificFile).to receive(:new).and_return(plugin_source)
      allow(subject).to receive(:internal_install)
    end

    it "should return plugin gem specification" do
      expect(subject.install_local(plugin_path)).to eq(plugin_spec)
    end

    it "should set custom sources" do
      expect(subject).to receive(:internal_install) do |info, update, opts|
        expect(info[plugin_name]["sources"]).to eq(sources)
      end
      subject.install_local(plugin_path, sources: sources)
    end

    it "should not set the update parameter" do
      expect(subject).to receive(:internal_install) do |info, update, opts|
        expect(update).to be_nil
      end
      subject.install_local(plugin_path)
    end

    it "should not set plugin as environment local by default" do
      expect(subject).to receive(:internal_install) do |info, update, opts|
        expect(opts[:env_local]).to be_falsey
      end
      subject.install_local(plugin_path)
    end

    it "should set if plugin is environment local" do
      expect(subject).to receive(:internal_install) do |info, update, opts|
        expect(opts[:env_local]).to be_truthy
      end
      subject.install_local(plugin_path, env_local: true)
    end
  end

  describe "#update" do
    let(:plugins){ :plugins }
    let(:specific){ [] }

    after{ subject.update(plugins, specific) }

    it "should mark update as true" do
      expect(subject).to receive(:internal_install) do |info, update, opts|
        expect(update).to be_truthy
      end
    end

    context "with specific plugins named" do
      let(:specific){ ["PLUGIN_NAME"] }

      it "should set update to specific names" do
        expect(subject).to receive(:internal_install) do |info, update, opts|
          expect(update[:gems]).to eq(specific)
        end
      end
    end
  end

  describe "#vagrant_internal_specs" do
    let(:vagrant_spec) { double("vagrant_spec", name: "vagrant", version: Gem::Version.new(Vagrant::VERSION),
      activated?: vagrant_spec_activated, activate: nil, runtime_dependencies: vagrant_dep_specs) }
    let(:spec_list) { [] }
    let(:spec_dirs) { [] }
    let(:spec_default_dir) { "/dev/null" }
    let(:dir_spec_list) { [] }
    let(:vagrant_spec_activated) { true }
    let(:vagrant_dep_specs) { [] }

    before do
      allow(Gem::Specification).to receive(:find) { |&b| vagrant_spec if b.call(vagrant_spec) }
      allow(Gem::Specification).to receive(:find_all).and_return(spec_list)
      allow(Gem::Specification).to receive(:dirs).and_return(spec_dirs)
      allow(Gem::Specification).to receive(:default_specifications_dir).and_return(spec_default_dir)
      allow(Gem::Specification).to receive(:each_spec).and_return(dir_spec_list)
    end

    it "should return an empty list" do
      expect(subject.send(:vagrant_internal_specs)).to eq([])
    end

    context "when vagrant specification is not activated" do
      let(:vagrant_spec_activated) { false }

      it "should activate the specification" do
        expect(vagrant_spec).to receive(:activate)
        subject.send(:vagrant_internal_specs)
      end
    end

    context "when vagrant specification is not found" do
      before { allow(Gem::Specification).to receive(:find).and_return(nil) }

      it "should raise not found error" do
        expect { subject.send(:vagrant_internal_specs) }.to raise_error(Vagrant::Errors::SourceSpecNotFound)
      end
    end

    context "when bundler is not defined" do
      before { expect(Vagrant).to receive(:in_bundler?).and_return(false) }

      context "when running inside the installer" do
        before { expect(Vagrant).to receive(:in_installer?).and_return(true) }

        it "should load gem specification directories" do
          expect(Gem::Specification).to receive(:dirs).and_return(spec_dirs)
          subject.send(:vagrant_internal_specs)
        end

        context "when checking paths" do
          let(:spec_dirs) { [double("spec-dir", start_with?: in_user_dir)] }
          let(:in_user_dir) { true }
          let(:user_dir) { double("user-dir") }

          before { allow(Gem).to receive(:user_dir).and_return(user_dir) }

          it "should check if path is within local user directory" do
            expect(spec_dirs.first).to receive(:start_with?).with(user_dir).and_return(false)
            subject.send(:vagrant_internal_specs)
          end

          context "when path is not within user directory" do
            let(:in_user_dir) { false }

            it "should use path when loading specs" do
              expect(Gem::Specification).to receive(:each_spec) { |arg| expect(arg).to include(spec_dirs.first) }
              subject.send(:vagrant_internal_specs)
            end
          end
        end
      end

      context "when running outside the installer" do
        before { expect(Vagrant).to receive(:in_installer?).and_return(false) }

        it "should not load gem specification directories" do
          expect(Gem::Specification).not_to receive(:dirs)
          subject.send(:vagrant_internal_specs)
        end
      end
    end
  end

  describe Vagrant::Bundler::PluginSet do
    let(:name) { "test-gem" }
    let(:version) { "1.0.0" }
    let(:directory) { @directory ||= Dir.mktmpdir("vagrant-bundler-test") }

    after do
      FileUtils.rm_rf(@directory) if @directory
      @directory = nil
    end

    describe "#add_vendor_gem" do
      context "when spec file does not exist" do
        it "should raise a not found error" do
          expect { subject.add_vendor_gem(name, directory) }.to raise_error(Gem::GemNotFoundException)
        end
      end

      context "when spec file exists" do
        before do
          spec = Gem::Specification.new(name, version)
          File.write(File.join(directory, "#{name}.gemspec"), spec.to_ruby)
        end

        it "should load the specification" do
          expect(subject.add_vendor_gem(name, directory)).to be_a(Gem::Specification)
        end

        it "should set the full path in specification" do
          spec = subject.add_vendor_gem(name, directory)
          expect(spec.full_gem_path).to eq(directory)
        end
      end
    end

    describe "#find_all" do
      let(:request) { Gem::Resolver::DependencyRequest.new(dependency, nil) }
      let(:dependency) { Gem::Dependency.new("test-gem", requirement) }
      let(:requirement) { Gem::Requirement.new(version) }

      context "when specification is not included in set" do
        it "should return empty array" do
          expect(subject.find_all(request)).to eq([])
        end
      end

      context "when specification is included in set" do
        before do
          spec = Gem::Specification.new(name, version)
          File.write(File.join(directory, "#{name}.gemspec"), spec.to_ruby)
          subject.add_vendor_gem(name, directory)
        end

        it "should return a vendor specification instance" do
          expect(subject.find_all(request).first).to be_a(Gem::Resolver::VendorSpecification)
        end
      end
    end
  end
end
