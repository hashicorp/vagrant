# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require_relative "../base"
require Vagrant.source_root.join("plugins/providers/virtualbox/driver/base")

describe VagrantPlugins::ProviderVirtualBox::Driver::Base do
  describe "#env_lang" do
    context "when locale command is not available" do
      before do
        allow(Vagrant::Util::Which).to receive(:which).with("locale").and_return(false)
      end

      it "should return default value" do
        expect(subject.send(:env_lang)).to eq({LANG: "C"})
      end
    end

    context "when the locale command is available" do
      let(:result) { Vagrant::Util::Subprocess::Result.new(exit_code, stdout, stderr) }
      let(:stderr) { "" }
      let(:stdout) { "C.default" }
      let(:exit_code) { 0 }

      before do
        allow(Vagrant::Util::Which).to receive(:which).with("locale").and_return(true)
        allow(Vagrant::Util::Subprocess).to receive(:execute).with("locale", "-a").and_return(result)
      end

      context "when locale command errors" do
        let(:exit_code) { 1 }

        it "should return default value" do
          expect(subject.send(:env_lang)).to eq({LANG: "C"})
        end
      end

      context "when locale command does not error" do
        let(:exit_code) { 0 }
        let(:base) { "de_AT.utf8\nde_BE.utf8\nde_CH.utf8\nde_DE.utf8\nde_IT.utf8\nde_LI.utf8\nde_LU.utf8\nen_AG\nen_AG.utf8\nen_AU.utf8\nen_BW.utf8\nen_CA.utf8\nen_DK.utf8\nen_GB.utf8\nen_HK.utf8\nen_IE.utf8\nen_IL\nen_IL.utf8\nen_IN\nen_IN.utf8\nen_NG\n" }

        context "when stdout includes C" do
          let(:stdout) { "#{base}C\n" }

          it "should use C for the lang" do
            expect(subject.send(:env_lang)).to eq({LANG: "C"})
          end

          context "when stdout includes UTF-8 variants of C" do
            let(:stdout) { "#{base}C\nC.UTF-8" }

            it "should use the UTF-8 variant" do
              expect(subject.send(:env_lang)).to eq({LANG: "C.UTF-8"})
            end
          end

          context "when stdout includes utf8 variants of C" do
            let(:stdout) { "#{base}C\nC.utf8" }

            it "should use the utf8 variant" do
              expect(subject.send(:env_lang)).to eq({LANG: "C.utf8"})
            end
          end
        end

        context "when stdout does not include C" do
          context "when stdout includes C.UTF-8" do
            let(:stdout) { "#{base}C.UTF-8\n"}

            it "should use C.UTF-8 for the lang" do
              expect(subject.send(:env_lang)).to eq({LANG: "C.UTF-8"})
            end
          end

          context "when stdout includes C.utf8" do
            let(:stdout) { "#{base}C.utf8\n"}

            it "should use C.utf8 for the lang" do
              expect(subject.send(:env_lang)).to eq({LANG: "C.utf8"})
            end
          end

          context "when stdout includes POSIX" do
            let(:stdout) { "#{base}POSIX\n"}

            it "should use POSIX for the lang" do
              expect(subject.send(:env_lang)).to eq({LANG: "POSIX"})
            end
          end

          context "when stdout includes en_US.UTF-8" do
            let(:stdout) { "#{base}en_US.UTF-8\n"}

            it "should use en_US.UTF-8 for the lang" do
              expect(subject.send(:env_lang)).to eq({LANG: "en_US.UTF-8"})
            end
          end

          context "when stdout includes en_US.utf8" do
            let(:stdout) { "#{base}en_US.utf8\n"}

            it "should use en_US.utf8 for the lang" do
              expect(subject.send(:env_lang)).to eq({LANG: "en_US.utf8"})
            end
          end
        end

        context "when stdout does not include any variations" do
          let(:stdout) { base }

          it "should default to C" do
            expect(subject.send(:env_lang)).to eq({LANG: "C"})
          end
        end
      end
    end
  end
end
