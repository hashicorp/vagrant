require_relative "../../../../base"

describe "VagrantPlugins::GuestLinux::Cap::FileSystem" do
  let(:caps) do
    VagrantPlugins::GuestLinux::Plugin
      .components
      .guest_capabilities[:linux]
  end

  let(:machine) { double("machine", communicate: comm) }
  let(:comm) { double("comm") }

  before { allow(comm).to receive(:execute) }

  describe ".create_tmp_path" do
    let(:cap) { caps.get(:create_tmp_path) }
    let(:opts) { {} }

    it "should generate path on guest" do
      expect(comm).to receive(:execute).with(/mktemp/)
      cap.create_tmp_path(machine, opts)
    end

    it "should capture path generated on guest" do
      expect(comm).to receive(:execute).with(/mktemp/).and_yield(:stdout, "TMP_PATH")
      expect(cap.create_tmp_path(machine, opts)).to eq("TMP_PATH")
    end

    it "should strip newlines on path" do
      expect(comm).to receive(:execute).with(/mktemp/).and_yield(:stdout, "TMP_PATH\n")
      expect(cap.create_tmp_path(machine, opts)).to eq("TMP_PATH")
    end

    context "when type is a directory" do
      before { opts[:type] = :directory }

      it "should create guest path as a directory" do
        expect(comm).to receive(:execute).with(/-d/)
        cap.create_tmp_path(machine, opts)
      end
    end
  end

  describe ".decompress_tgz" do
    let(:cap) { caps.get(:decompress_tgz) }
    let(:comp) { "compressed_file" }
    let(:dest) { "path/to/destination" }

    before { allow(cap).to receive(:create_tmp_path).and_return("TMP_DIR") }
    after{ cap.decompress_tgz(machine, comp, dest, opts) }

    [false, true].each do |sudo_flag|
      context "sudo flag: #{sudo_flag}" do
        let(:opts) { {sudo: sudo_flag} }

        it "should create temporary directory for extraction" do
          expect(cap).to receive(:create_tmp_path)
        end

        it "should extract file with tar" do
          expect(comm).to receive(:execute).with(/tar/, sudo: sudo_flag)
        end

        it "should extract file to temporary directory" do
          expect(comm).to receive(:execute).with(/TMP_DIR/, sudo: sudo_flag)
        end

        it "should remove compressed file from guest" do
          expect(comm).to receive(:execute).with(/rm .*#{comp}/, sudo: sudo_flag)
        end

        it "should remove extraction directory from guest" do
          expect(comm).to receive(:execute).with(/rm .*TMP_DIR/, sudo: sudo_flag)
        end

        it "should create parent directories for destination" do
          expect(comm).to receive(:execute).with(/mkdir -p .*to'/, sudo: sudo_flag)
        end

        context "when type is directory" do
          before { opts[:type] = :directory }

          it "should create destination directory" do
            expect(comm).to receive(:execute).with(/mkdir -p .*destination'/, sudo: sudo_flag)
          end
        end
      end
    end
  end

  describe ".decompress_zip" do
    let(:cap) { caps.get(:decompress_zip) }
    let(:comp) { "compressed_file" }
    let(:dest) { "path/to/destination" }

    before { allow(cap).to receive(:create_tmp_path).and_return("TMP_DIR") }
    after{ cap.decompress_zip(machine, comp, dest, opts) }

    [false, true].each do |sudo_flag|
      context "sudo flag: #{sudo_flag}" do
        let(:opts) { {sudo: sudo_flag} }

        it "should create temporary directory for extraction" do
          expect(cap).to receive(:create_tmp_path)
        end

        it "should extract file with zip" do
          expect(comm).to receive(:execute).with(/zip/, sudo: sudo_flag)
        end

        it "should extract file to temporary directory" do
          expect(comm).to receive(:execute).with(/TMP_DIR/, sudo: sudo_flag)
        end

        it "should remove compressed file from guest" do
          expect(comm).to receive(:execute).with(/rm .*#{comp}/, sudo: sudo_flag)
        end

        it "should remove extraction directory from guest" do
          expect(comm).to receive(:execute).with(/rm .*TMP_DIR/, sudo: sudo_flag)
        end

        it "should create parent directories for destination" do
          expect(comm).to receive(:execute).with(/mkdir -p .*to'/, sudo: sudo_flag)
        end

        context "when type is directory" do
          before { opts[:type] = :directory }

          it "should create destination directory" do
            expect(comm).to receive(:execute).with(/mkdir -p .*destination'/, sudo: sudo_flag)
          end
        end
      end
    end
  end

  describe ".create_directories" do
    let(:cap) { caps.get(:create_directories) }
    let(:dirs) { %w(dir1 dir2) }

    before { allow(cap).to receive(:create_tmp_path).and_return("TMP_DIR") }

    [false, true].each do |sudo_flag|
      context "sudo flag: #{sudo_flag}" do
        let(:opts) { {sudo: sudo_flag} }

       after { expect(cap.create_directories(machine, dirs, opts)).to eql(dirs) }

        context "passes directories to be create" do
          let(:temp_file) do
            double("temp_file").tap do |temp_file|
              allow(temp_file).to receive(:binmode)
              allow(temp_file).to receive(:close)
              allow(temp_file).to receive(:path).and_return("temp_path")
              allow(temp_file).to receive(:unlink)
            end
          end
          let(:exec_block) do
            Proc.new do |arg, &proc|
              lines = arg.split("\n")
              expect(lines[lines.length - 2]).to match(/TMP_DIR/)
              dirs.each do |dir|
                proc.call :stdout, "mkdir: created directory '#{dir}'\n"
              end
            end
          end

          before do
            allow(Tempfile).to receive(:new).and_return(temp_file)
            allow(temp_file).to receive(:write)
            allow(temp_file).to receive(:close)
            allow(comm).to receive(:upload)
            allow(comm).to receive(:execute, &exec_block)
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
            expect(comm).to receive(:execute, &exec_block).with(/bash -c .*/, sudo: sudo_flag)
          end
        end

        context "passes empty dir list" do
          let(:dirs) { [] }

          after { expect(cap.create_directories(machine, dirs, opts)).to eql([]) }

          it "does nothing" do
            expect(cap).to receive(:create_tmp_path).never
            expect(Tempfile).to receive(:new).never
            expect(comm).to receive(:upload).never
            expect(comm).to receive(:execute).never
          end
        end
      end
    end
  end
end
