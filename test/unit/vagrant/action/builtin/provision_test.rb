require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/vm")

describe Vagrant::Action::Builtin::Provision do
  include_context "unit"

  let(:app) { lambda { |env| } }
  let(:env) {
    { machine: machine, ui: ui, hook: hook, provision_ignore_sentinel: false }
  }
  let(:hook){ double("hook") }

  let(:machine) do
    double("machine").tap do |machine|
      allow(machine).to receive(:id).and_return('machine-id')
      allow(machine).to receive(:data_dir).and_return(data_dir)
      allow(machine).to receive(:config).and_return(machine_config)
      allow(machine).to receive(:env).and_return(machine_env)
    end
  end

  let(:machine_config) do
    double("machine_config").tap do |config|
      allow(config).to receive(:vm).and_return(vm_config)
    end
  end

  let(:data_dir){ temporary_dir }

  let(:machine_env) do
    isolated_environment.tap do |i_env|
      allow(i_env).to receive(:data_dir).and_return(data_dir)
      allow(i_env).to receive(:lock).and_yield
    end
  end

  let(:vm_config) do
    double("machine_vm_config").tap do |config|
      allow(config).to receive(:provisioners).and_return([])
    end
  end

  let(:ui) do
    double("ui").tap do |result|
      allow(result).to receive(:info)
    end
  end

  let(:instance){ described_class.new(app, env) }

  describe "#call" do
    context "with no provisioners defined" do
      it "should process empty set of provisioners" do
        expect(instance.call(env)).to eq([])
      end

      context "with provisioning disabled" do
        before{ env[:provision_enabled] = false }
        after{ env.delete(:provision_enabled) }

        it "should not process any provisioners" do
          expect(instance.call(env)).to be_nil
        end
      end
    end

    context "with single provisioner defined" do
      let(:provisioner) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("spec-test", :shell)
        prov.config = provisioner_config
        prov
      end
      let(:provisioner_config){ {} }

      before{ expect(vm_config).to receive(:provisioners).and_return([provisioner]) }

      it "should call the defined provisioner" do
        expect(hook).to receive(:call).with(:provisioner_run, anything)
        instance.call(env)
      end

      context "with provisioning disabled" do
        before{ env[:provision_enabled] = false }
        after{ env.delete(:provision_enabled) }

        it "should not process any provisioners" do
          expect(hook).not_to receive(:call).with(:provisioner_run, anything)
          expect(instance.call(env)).to be_nil
        end
      end

      context "with provisioner configured to run once" do
        before{ provisioner.run = :once }

        it "should run if machine is not provisioned" do
          expect(hook).to receive(:call).with(:provisioner_run, anything)
          instance.call(env)
        end

        it "should not run if machine is provisioned" do
          File.open(File.join(data_dir.to_s, "action_provision"), "w") do |file|
            file.write("1.5:machine-id")
          end
          expect(hook).not_to receive(:call).with(:provisioner_run, anything)
          instance.call(env)
        end

        it "should not run if provision types are set and provisioner is not included" do
          env[:provision_types] = ["other-provisioner", "other-test"]
          expect(hook).not_to receive(:call).with(:provisioner_run, anything)
          instance.call(env)
        end

        it "should run if provision types are set and include provisioner name" do
          env[:provision_types] = ["spec-test"]
          expect(hook).to receive(:call).with(:provisioner_run, anything)
          instance.call(env)
        end

        it "should run if provision types are set and include provisioner type" do
          env[:provision_types] = [:shell]
          expect(hook).to receive(:call).with(:provisioner_run, anything)
          instance.call(env)
        end
      end

      context "with provisioner configured to run always" do
        before{ provisioner.run = :always }

        it "should run if machine is not provisioned" do
          expect(hook).to receive(:call).with(:provisioner_run, anything)
          instance.call(env)
        end

        it "should run if machine is provisioned" do
          File.open(File.join(data_dir.to_s, "action_provision"), "w") do |file|
            file.write("1.5:machine-id")
          end
          expect(hook).to receive(:call).with(:provisioner_run, anything)
          instance.call(env)
        end

        it "should not run if provision types are set and provisioner is not included" do
          env[:provision_types] = ["other-provisioner", "other-test"]
          expect(hook).not_to receive(:call).with(:provisioner_run, anything)
          instance.call(env)
        end

        it "should run if provision types are set and include provisioner name" do
          env[:provision_types] = ["spec-test"]
          expect(hook).to receive(:call).with(:provisioner_run, anything)
          instance.call(env)
        end

        it "should run if provision types are set and include provisioner type" do
          env[:provision_types] = [:shell]
          expect(hook).to receive(:call).with(:provisioner_run, anything)
          instance.call(env)
        end
      end

      context "with provisioner configured to never run" do
        before{ provisioner.run = :never }

        it "should not run if machine is not provisioned" do
          expect(hook).not_to receive(:call).with(:provisioner_run, anything)
          instance.call(env)
        end

        it "should not run if machine is provisioned" do
          File.open(File.join(data_dir.to_s, "action_provision"), "w") do |file|
            file.write("1.5:machine-id")
          end
          expect(hook).not_to receive(:call).with(:provisioner_run, anything)
          instance.call(env)
        end

        it "should not run if provision types are set and provisioner is not included" do
          env[:provision_types] = ["other-provisioner", "other-test"]
          expect(hook).not_to receive(:call).with(:provisioner_run, anything)
          instance.call(env)
        end

        it "should run if provision types are set and include provisioner name" do
          env[:provision_types] = ["spec-test"]
          expect(hook).to receive(:call).with(:provisioner_run, anything)
          instance.call(env)
        end

        it "should run if provision types are set and include provisioner name and machine is provisioned" do
          File.open(File.join(data_dir.to_s, "action_provision"), "w") do |file|
            file.write("1.5:machine-id")
          end
          env[:provision_types] = ["spec-test"]
          expect(hook).to receive(:call).with(:provisioner_run, anything)
          instance.call(env)
        end

        it "should not run if provision types are set and include provisioner type" do
          env[:provision_types] = [:shell]
          expect(hook).not_to receive(:call).with(:provisioner_run, anything)
          instance.call(env)
        end
      end
    end
  end
end
