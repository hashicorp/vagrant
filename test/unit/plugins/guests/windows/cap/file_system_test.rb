require 'json'
require_relative "../../../../base"

describe "VagrantPlugins::GuestWindows::Cap::FileSystem" do
  let(:caps) do
    VagrantPlugins::GuestWindows::Plugin
      .components
      .guest_capabilities[:windows]
  end

  let(:machine) { double("machine", communicate: comm) }
  let(:comm) { double("comm") }

  before { allow(comm).to receive(:execute) }

  describe ".create_tmp_path" do
    let(:cap) { caps.get(:create_tmp_path) }
    let(:opts) { {} }

    it "should generate path on guest" do
      expect(comm).to receive(:execute).with(/GetRandomFileName/, any_args)
      cap.create_tmp_path(machine, opts)
    end

    it "should capture path generated on guest" do
      expect(comm).to receive(:execute).with(/Write-Output/, any_args).and_yield(:stdout, "TMP_PATH")
      expect(cap.create_tmp_path(machine, opts)).to eq("TMP_PATH")
    end

    it "should strip newlines on path" do
      expect(comm).to receive(:execute).with(/Write-Output/, any_args).and_yield(:stdout, "TMP_PATH\r\n")
      expect(cap.create_tmp_path(machine, opts)).to eq("TMP_PATH")
    end

    context "when type is a directory" do
      before { opts[:type] = :directory }

      it "should create guest path as a directory" do
        expect(comm).to receive(:execute).with(/CreateDirectory/, any_args)
        cap.create_tmp_path(machine, opts)
      end
    end
  end

  describe ".decompress_zip" do
    let(:cap) { caps.get(:decompress_zip) }
    let(:comp) { "compressed_file" }
    let(:dest) { "path/to/destination" }
    let(:opts) { {} }

    before { allow(cap).to receive(:create_tmp_path).and_return("TMP_DIR") }
    after{ cap.decompress_zip(machine, comp, dest, opts) }

    it "should create temporary directory for extraction" do
      expect(cap).to receive(:create_tmp_path)
    end

    it "should extract file with zip" do
      expect(comm).to receive(:execute).with(/copyhere/, any_args)
    end

    it "should extract file to temporary directory" do
      expect(comm).to receive(:execute).with(/TMP_DIR/, any_args)
    end

    it "should remove compressed file from guest" do
      expect(comm).to receive(:execute).with(/Remove-Item .*#{comp}/, any_args)
    end

    it "should remove extraction directory from guest" do
      expect(comm).to receive(:execute).with(/Remove-Item .*TMP_DIR/, any_args)
    end

    it "should create parent directories for destination" do
      expect(comm).to receive(:execute).with(/New-Item .*Directory .*to\\"/, any_args)
    end

    context "when type is directory" do
      before { opts[:type] = :directory }

      it "should create destination directory" do
        expect(comm).to receive(:execute).with(/New-Item .*Directory .*destination"/, any_args)
      end
    end
  end

  describe ".create_directories" do
    let(:cap) { caps.get(:create_directories) }
    let(:dirs) { %w(dir1 dir2) }

    before { allow(cap).to receive(:create_tmp_path).and_return("TMP_DIR") }
    after { expect(cap.create_directories(machine, dirs)).to eql(dirs) }

    context "passes directories to be create" do
      let(:temp_file) do
        double("temp_file").tap do |temp_file|
          allow(temp_file).to receive(:close)
          allow(temp_file).to receive(:path).and_return("temp_path")
          allow(temp_file).to receive(:unlink)
        end
      end
      let(:sudo_block) do
        Proc.new do |arg, &proc|
          lines = arg.split("\n")
          expect(lines[0]).to match(/TMP_DIR/)
          dirs.each do |dir|
            proc.call :stdout, { FullName: dir }.to_json
          end
        end
      end
      let(:cmd) do
        <<-EOH.gsub(/^ {6}/, "")
      $files = Get-Content TMP_DIR
      foreach ($file in $files) {
        if (-Not (Test-Path($file))) {
          ConvertTo-Json (New-Item $file -type directory -Force | Select-Object FullName)
        } else {
          if (-Not ((Get-Item $file) -is [System.IO.DirectoryInfo])) {
            # Remove the file
            Remove-Item -Path $file -Force
            ConvertTo-Json (New-Item $file -type directory -Force | Select-Object FullName)
          }
        }
      }
        EOH
      end

      before do
        allow(Tempfile).to receive(:new).and_return(temp_file)
        allow(temp_file).to receive(:write)
        allow(temp_file).to receive(:close)
        allow(comm).to receive(:upload)
        allow(comm).to receive(:execute, &sudo_block)
      end

      it "creates temporary file on guest" do
        expect(cap).to receive(:create_tmp_path)
      end

      it "creates a temporary file to write dir list" do
        expect(Tempfile).to receive(:new).and_return(temp_file)
      end

      it "writes dir list to a local temporary file" do
        expect(temp_file).to receive(:write).with(dirs.join("\n") + "\n")
      end

      it "uploads the local temporary file with dir list to guest" do
        expect(comm).to receive(:upload).with("temp_path", "TMP_DIR")
      end

      it "executes bash script to create directories on guest" do
        expect(comm).to receive(:execute, &sudo_block).with(cmd, shell: :powershell)
      end
    end

    context "passes empty dir list" do
      let(:dirs) { [] }

      after { expect(cap.create_directories(machine, dirs)).to eql([]) }

      it "does nothing" do
        expect(cap).to receive(:create_tmp_path).never
        expect(Tempfile).to receive(:new).never
        expect(comm).to receive(:upload).never
        expect(comm).to receive(:execute).never
      end
    end
  end
end
