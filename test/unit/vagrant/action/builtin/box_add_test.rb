require "digest/sha1"
require "pathname"
require "tempfile"
require "tmpdir"
require "webrick"

require File.expand_path("../../../../base", __FILE__)

require "vagrant/util/file_checksum"

describe Vagrant::Action::Builtin::BoxAdd do
  include_context "unit"

  let(:app) { lambda { |env| } }
  let(:env) { {
    box_collection: box_collection,
    hook: Proc.new { |name, env| env },
    tmp_path: Pathname.new(Dir.mktmpdir),
    ui: Vagrant::UI::Silent.new,
  } }

  subject { described_class.new(app, env) }

  let(:box_collection) { double("box_collection") }
  let(:iso_env) { isolated_environment }

  let(:box) do
    box_dir = iso_env.box3("foo", "1.0", :virtualbox)
    Vagrant::Box.new("foo", :virtualbox, "1.0", box_dir)
  end

  # Helper to quickly SHA1 checksum a path
  def checksum(path)
    FileChecksum.new(path, Digest::SHA1).checksum
  end

  def with_web_server(path, **opts)
    tf = Tempfile.new("vagrant")
    tf.close

    opts[:json_type] ||= "application/json"

    mime_types = WEBrick::HTTPUtils::DefaultMimeTypes
    mime_types.store "json", opts[:json_type]

    port   = 3838
    server = WEBrick::HTTPServer.new(
      AccessLog: [],
      Logger: WEBrick::Log.new(tf.path, 7),
      Port: port,
      DocumentRoot: path.dirname.to_s,
      MimeTypes: mime_types)
    thr = Thread.new { server.start }
    yield port
  ensure
    server.shutdown rescue nil
    thr.join rescue nil
  end

  before do
    box_collection.stub(find: nil)
  end

  context "with box file directly" do
    it "adds it" do
      box_path = iso_env.box2_file(:virtualbox)

      env[:box_name] = "foo"
      env[:box_url] = box_path.to_s

      expect(box_collection).to receive(:add).with { |path, name, version, **opts|
        expect(checksum(path)).to eq(checksum(box_path))
        expect(name).to eq("foo")
        expect(version).to eq("0")
        expect(opts[:metadata_url]).to be_nil
        true
      }.and_return(box)

      expect(app).to receive(:call).with(env)

      subject.call(env)
    end

    it "adds from multiple URLs" do
      box_path = iso_env.box2_file(:virtualbox)

      env[:box_name] = "foo"
      env[:box_url] = [
        "/foo/bar/baz",
        box_path.to_s,
      ]

      expect(box_collection).to receive(:add).with { |path, name, version, **opts|
        expect(checksum(path)).to eq(checksum(box_path))
        expect(name).to eq("foo")
        expect(version).to eq("0")
        expect(opts[:metadata_url]).to be_nil
        true
      }.and_return(box)

      expect(app).to receive(:call).with(env)

      subject.call(env)
    end

    it "adds from HTTP URL" do
      box_path = iso_env.box2_file(:virtualbox)
      with_web_server(box_path) do |port|
        env[:box_name] = "foo"
        env[:box_url] = "http://127.0.0.1:#{port}/#{box_path.basename}"

        expect(box_collection).to receive(:add).with { |path, name, version, **opts|
          expect(checksum(path)).to eq(checksum(box_path))
          expect(name).to eq("foo")
          expect(version).to eq("0")
          expect(opts[:metadata_url]).to be_nil
          true
        }.and_return(box)

        expect(app).to receive(:call).with(env)

        subject.call(env)
      end
    end

    it "raises an error if no name is given" do
      box_path = iso_env.box2_file(:virtualbox)

      env[:box_url] = box_path.to_s

      expect(box_collection).to receive(:add).never
      expect(app).to receive(:call).never

      expect { subject.call(env) }.
        to raise_error(Vagrant::Errors::BoxAddNameRequired)
    end

    it "raises an error if the box already exists" do
      box_path = iso_env.box2_file(:virtualbox)

      env[:box_name] = "foo"
      env[:box_url] = box_path.to_s
      env[:box_provider] = "virtualbox"

      expect(box_collection).to receive(:find).with(
        "foo", ["virtualbox"], "0").and_return(box)
      expect(box_collection).to receive(:add).never
      expect(app).to receive(:call).never

      expect { subject.call(env) }.
        to raise_error(Vagrant::Errors::BoxAlreadyExists)
    end

    it "raises an error if checksum specified and doesn't match" do
      box_path = iso_env.box2_file(:virtualbox)

      env[:box_name] = "foo"
      env[:box_url] = box_path.to_s
      env[:box_checksum] = checksum(box_path) + "A"
      env[:box_checksum_type] = "sha1"

      expect(box_collection).to receive(:add).never
      expect(app).to receive(:call).never

      expect { subject.call(env) }.
        to raise_error(Vagrant::Errors::BoxChecksumMismatch)
    end

    it "raises an error if the box path doesn't exist" do
      box_path = iso_env.box2_file(:virtualbox)

      env[:box_name] = "foo"
      env[:box_url] = box_path.to_s + "nope"

      expect(box_collection).to receive(:add).never
      expect(app).to receive(:call).never

      expect { subject.call(env) }.
        to raise_error(Vagrant::Errors::DownloaderError)
    end

    it "raises an error if a version was specified" do
      box_path = iso_env.box2_file(:virtualbox)

      env[:box_name] = "foo"
      env[:box_url] = box_path.to_s
      env[:box_version] = "1"

      expect(box_collection).to receive(:add).never

      expect(app).to receive(:call).never

      expect { subject.call(env) }.
        to raise_error(Vagrant::Errors::BoxAddDirectVersion)
    end

    it "force adds if exists and specified" do
      box_path = iso_env.box2_file(:virtualbox)

      env[:box_force] = true
      env[:box_name] = "foo"
      env[:box_url] = box_path.to_s
      env[:box_provider] = "virtualbox"

      box_collection.stub(find: box)
      expect(box_collection).to receive(:add).with { |path, name, version, **opts|
        expect(checksum(path)).to eq(checksum(box_path))
        expect(name).to eq("foo")
        expect(version).to eq("0")
        expect(opts[:metadata_url]).to be_nil
        true
      }.and_return(box)
      expect(app).to receive(:call).with(env).once

      subject.call(env)
    end
  end

  context "with box metadata" do
    it "adds from HTTP URL" do
      box_path = iso_env.box2_file(:virtualbox)
      tf = Tempfile.new(["vagrant", ".json"]).tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5"
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{box_path}"
                }
              ]
            }
          ]
        }
        RAW
        f.close
      end

      md_path = Pathname.new(tf.path)
      with_web_server(md_path) do |port|
        env[:box_url] = "http://127.0.0.1:#{port}/#{md_path.basename}"

        expect(box_collection).to receive(:add).with { |path, name, version, **opts|
          expect(name).to eq("foo/bar")
          expect(version).to eq("0.7")
          expect(checksum(path)).to eq(checksum(box_path))
          expect(opts[:metadata_url]).to eq(env[:box_url])
          true
        }.and_return(box)

        expect(app).to receive(:call).with(env)

        subject.call(env)
      end
    end

    it "adds from HTTP URL with complex JSON mime type" do
      box_path = iso_env.box2_file(:virtualbox)
      tf = Tempfile.new(["vagrant", ".json"]).tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5"
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{box_path}"
                }
              ]
            }
          ]
        }
        RAW
        f.close
      end

      opts = { json_type: "application/json; charset=utf-8" }

      md_path = Pathname.new(tf.path)
      with_web_server(md_path, **opts) do |port|
        env[:box_url] = "http://127.0.0.1:#{port}/#{md_path.basename}"

        expect(box_collection).to receive(:add).with { |path, name, version, **opts|
          expect(name).to eq("foo/bar")
          expect(version).to eq("0.7")
          expect(checksum(path)).to eq(checksum(box_path))
          expect(opts[:metadata_url]).to eq(env[:box_url])
          true
        }.and_return(box)

        expect(app).to receive(:call).with(env)

        subject.call(env)
      end
    end

    it "adds from shorthand path" do
      box_path = iso_env.box2_file(:virtualbox)
      td = Pathname.new(Dir.mktmpdir)
      tf = td.join("mitchellh", "precise64.json")
      tf.dirname.mkpath
      tf.open("w") do |f|
        f.write(<<-RAW)
        {
          "name": "mitchellh/precise64",
          "versions": [
            {
              "version": "0.5"
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{box_path}"
                }
              ]
            }
          ]
        }
        RAW
      end

      with_web_server(tf.dirname) do |port|
        url = "http://127.0.0.1:#{port}"
        env[:box_url] = "mitchellh/precise64.json"

        expect(box_collection).to receive(:add).with { |path, name, version, **opts|
          expect(name).to eq("mitchellh/precise64")
          expect(version).to eq("0.7")
          expect(checksum(path)).to eq(checksum(box_path))
          expect(opts[:metadata_url]).to eq(
            "#{url}/#{env[:box_url]}")
          true
        }.and_return(box)

        expect(app).to receive(:call).with(env)

        with_temp_env("VAGRANT_SERVER_URL" => url) do
          subject.call(env)
        end
      end
    end

    it "add from shorthand path with configured server url" do
      box_path = iso_env.box2_file(:virtualbox)
      td = Pathname.new(Dir.mktmpdir)
      tf = td.join("mitchellh", "precise64.json")
      tf.dirname.mkpath
      tf.open("w") do |f|
        f.write(<<-RAW)
        {
          "name": "mitchellh/precise64",
          "versions": [
            {
              "version": "0.5"
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{box_path}"
                }
              ]
            }
          ]
        }
        RAW
      end

      with_web_server(tf.dirname) do |port|
        url = "http://127.0.0.1:#{port}"
        env[:box_url] = "mitchellh/precise64.json"
        env[:box_server_url] = url

        expect(box_collection).to receive(:add).with { |path, name, version, **opts|
          expect(name).to eq("mitchellh/precise64")
          expect(version).to eq("0.7")
          expect(checksum(path)).to eq(checksum(box_path))
          expect(opts[:metadata_url]).to eq(
            "#{url}/#{env[:box_url]}")
          true
        }.and_return(box)

        expect(app).to receive(:call).with(env)

        subject.call(env)
      end
    end

    it "authenticates HTTP URLs and adds them" do
      box_path = iso_env.box2_file(:virtualbox)
      tf = Tempfile.new(["vagrant", ".json"]).tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5"
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "bar"
                }
              ]
            }
          ]
        }
        RAW
        f.close
      end

      md_path = Pathname.new(tf.path)
      with_web_server(md_path) do |port|
        real_url = "http://127.0.0.1:#{port}/#{md_path.basename}"

        # Set the box URL to something fake so we can modify it in place
        env[:box_url] = "foo"

        env[:hook] = double("hook")
        allow(env[:hook]).to receive(:call) do |name, opts|
          expect(name).to eq(:authenticate_box_url)
          if opts[:box_urls] == ["foo"]
            next { box_urls: [real_url] }
          elsif opts[:box_urls] == ["bar"]
            next { box_urls: [box_path.to_s] }
          else
            raise "UNKNOWN: #{opts[:box_urls].inspect}"
          end
        end

        expect(box_collection).to receive(:add).with { |path, name, version, **opts|
          expect(name).to eq("foo/bar")
          expect(version).to eq("0.7")
          expect(checksum(path)).to eq(checksum(box_path))
          expect(opts[:metadata_url]).to eq("foo")
          true
        }.and_return(box)

        expect(app).to receive(:call).with(env)

        subject.call(env)
      end
    end

    it "adds from HTTP URL with a checksum" do
      box_path = iso_env.box2_file(:virtualbox)
      tf = Tempfile.new(["vagrant", ".json"]).tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5"
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{box_path}",
                  "checksum_type": "sha1",
                  "checksum": "#{checksum(box_path)}"
                }
              ]
            }
          ]
        }
        RAW
        f.close
      end

      md_path = Pathname.new(tf.path)
      with_web_server(md_path) do |port|
        env[:box_url] = "http://127.0.0.1:#{port}/#{md_path.basename}"

        expect(box_collection).to receive(:add).with { |path, name, version, **opts|
          expect(name).to eq("foo/bar")
          expect(version).to eq("0.7")
          expect(checksum(path)).to eq(checksum(box_path))
          expect(opts[:metadata_url]).to eq(env[:box_url])
          true
        }.and_return(box)

        expect(app).to receive(:call).with(env)

        subject.call(env)
      end
    end

    it "raises an exception if checksum given but not correct" do
      box_path = iso_env.box2_file(:virtualbox)
      tf = Tempfile.new(["vagrant", ".json"]).tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5"
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{box_path}",
                  "checksum_type": "sha1",
                  "checksum": "thisisnotcorrect"
                }
              ]
            }
          ]
        }
        RAW
        f.close
      end

      md_path = Pathname.new(tf.path)
      with_web_server(md_path) do |port|
        env[:box_url] = "http://127.0.0.1:#{port}/#{md_path.basename}"

        expect(box_collection).to receive(:add).never
        expect(app).to receive(:call).never

        expect { subject.call(env) }.
          to raise_error(Vagrant::Errors::BoxChecksumMismatch)
      end
    end

    it "raises an error if no Vagrant server is set" do
      tf = Tempfile.new("foo")
      tf.close

      env[:box_url] = "mitchellh/precise64.json"

      expect(box_collection).to receive(:add).never
      expect(app).to receive(:call).never

      Vagrant.stub(server_url: nil)

      expect { subject.call(env) }.
        to raise_error(Vagrant::Errors::BoxServerNotSet)
    end

    it "raises an error if shorthand is invalid" do
      tf = Tempfile.new("foo")
      tf.close

      with_web_server(Pathname.new(tf.path)) do |port|
        env[:box_url] = "mitchellh/precise64.json"

        expect(box_collection).to receive(:add).never
        expect(app).to receive(:call).never

        url = "http://127.0.0.1:#{port}"
        with_temp_env("VAGRANT_SERVER_URL" => url) do
          expect { subject.call(env) }.
            to raise_error(Vagrant::Errors::BoxAddShortNotFound)
        end
      end
    end

    it "raises an error if multiple metadata URLs are given" do
      box_path = iso_env.box2_file(:virtualbox)
      tf = Tempfile.new("vagrant").tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5"
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{box_path}"
                }
              ]
            }
          ]
        }
        RAW
        f.close
      end

      env[:box_url] = [
        "/foo/bar/baz",
        tf.path,
      ]
      expect(box_collection).to receive(:add).never
      expect(app).to receive(:call).never

      expect { subject.call(env) }.
        to raise_error(Vagrant::Errors::BoxAddMetadataMultiURL)
    end

    it "adds the latest version of a box with only one provider" do
      box_path = iso_env.box2_file(:virtualbox)
      tf = Tempfile.new("vagrant").tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5"
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{box_path}"
                }
              ]
            }
          ]
        }
        RAW
        f.close
      end

      env[:box_url] = tf.path
      expect(box_collection).to receive(:add).with { |path, name, version, **opts|
        expect(checksum(path)).to eq(checksum(box_path))
        expect(name).to eq("foo/bar")
        expect(version).to eq("0.7")
        expect(opts[:metadata_url]).to eq("file://#{tf.path}")
        true
      }.and_return(box)

      expect(app).to receive(:call).with(env)

      subject.call(env)
    end

    it "adds the latest version of a box with the specified provider" do
      box_path = iso_env.box2_file(:vmware)
      tf = Tempfile.new("vagrant").tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5"
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{iso_env.box2_file(:virtualbox)}"
                },
                {
                  "name": "vmware",
                  "url":  "#{box_path}"
                }
              ]
            }
          ]
        }
        RAW
        f.close
      end

      env[:box_url] = tf.path
      env[:box_provider] = "vmware"
      expect(box_collection).to receive(:add).with { |path, name, version, **opts|
        expect(checksum(path)).to eq(checksum(box_path))
        expect(name).to eq("foo/bar")
        expect(version).to eq("0.7")
        expect(opts[:metadata_url]).to eq("file://#{tf.path}")
        true
      }.and_return(box)

      expect(app).to receive(:call).with(env)

      subject.call(env)

      expect(env[:box_added]).to equal(box)
    end

    it "adds the latest version of a box with the specified provider, even if not latest" do
      box_path = iso_env.box2_file(:vmware)
      tf = Tempfile.new("vagrant").tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5"
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{iso_env.box2_file(:virtualbox)}"
                },
                {
                  "name": "vmware",
                  "url":  "#{box_path}"
                }
              ]
            },
            {
              "version": "1.5"
            }
          ]
        }
        RAW
        f.close
      end

      env[:box_url] = tf.path
      env[:box_provider] = "vmware"
      expect(box_collection).to receive(:add).with { |path, name, version, **opts|
        expect(checksum(path)).to eq(checksum(box_path))
        expect(name).to eq("foo/bar")
        expect(version).to eq("0.7")
        expect(opts[:metadata_url]).to eq("file://#{tf.path}")
        true
      }.and_return(box)

      expect(app).to receive(:call).with(env)

      subject.call(env)

      expect(env[:box_added]).to equal(box)
    end

    it "adds the constrained version of a box with the only provider" do
      box_path = iso_env.box2_file(:vmware)
      tf = Tempfile.new("vagrant").tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5",
              "providers": [
                {
                  "name": "vmware",
                  "url":  "#{box_path}"
                }
              ]
            },
            { "version": "1.1" }
          ]
        }
        RAW
        f.close
      end

      env[:box_url] = tf.path
      env[:box_version] = "~> 0.1"
      expect(box_collection).to receive(:add).with { |path, name, version, **opts|
        expect(checksum(path)).to eq(checksum(box_path))
        expect(name).to eq("foo/bar")
        expect(version).to eq("0.5")
        expect(opts[:metadata_url]).to eq("file://#{tf.path}")
        true
      }.and_return(box)

      expect(app).to receive(:call).with(env)

      subject.call(env)

      expect(env[:box_added]).to equal(box)
    end

    it "adds the constrained version of a box with the specified provider" do
      box_path = iso_env.box2_file(:vmware)
      tf = Tempfile.new("vagrant").tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5",
              "providers": [
                {
                  "name": "vmware",
                  "url":  "#{box_path}"
                },
                {
                  "name": "virtualbox",
                  "url":  "#{iso_env.box2_file(:virtualbox)}"
                }
              ]
            },
            { "version": "1.1" }
          ]
        }
        RAW
        f.close
      end

      env[:box_url] = tf.path
      env[:box_provider] = "vmware"
      env[:box_version] = "~> 0.1"
      expect(box_collection).to receive(:add).with { |path, name, version, **opts|
        expect(checksum(path)).to eq(checksum(box_path))
        expect(name).to eq("foo/bar")
        expect(version).to eq("0.5")
        expect(opts[:metadata_url]).to eq("file://#{tf.path}")
        true
      }.and_return(box)

      expect(app).to receive(:call).with(env)

      subject.call(env)

      expect(env[:box_added]).to equal(box)
    end

    it "adds the latest version of a box with any specified provider" do
      box_path = iso_env.box2_file(:vmware)
      tf = Tempfile.new("vagrant").tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{iso_env.box2_file(:virtualbox)}"
                }
              ]
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "vmware",
                  "url":  "#{box_path}"
                }
              ]
            }
          ]
        }
        RAW
        f.close
      end

      env[:box_url] = tf.path
      env[:box_provider] = ["virtualbox", "vmware"]
      expect(box_collection).to receive(:add).with { |path, name, version, **opts|
        expect(checksum(path)).to eq(checksum(box_path))
        expect(name).to eq("foo/bar")
        expect(version).to eq("0.7")
        expect(opts[:metadata_url]).to eq("file://#{tf.path}")
        true
      }.and_return(box)

      expect(app).to receive(:call).with(env)

      subject.call(env)

      expect(env[:box_added]).to equal(box)
    end

    it "asks the user what provider if multiple options" do
      box_path = iso_env.box2_file(:virtualbox)
      tf = Tempfile.new("vagrant").tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5"
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{box_path}"
                },
                {
                  "name": "vmware",
                  "url":  "#{iso_env.box2_file(:vmware)}"
                }
              ]
            }
          ]
        }
        RAW
        f.close
      end

      env[:box_url] = tf.path

      expect(env[:ui]).to receive(:ask).and_return("1")

      expect(box_collection).to receive(:add).with { |path, name, version, **opts|
        expect(checksum(path)).to eq(checksum(box_path))
        expect(name).to eq("foo/bar")
        expect(version).to eq("0.7")
        expect(opts[:metadata_url]).to eq("file://#{tf.path}")
        true
      }.and_return(box)

      expect(app).to receive(:call).with(env)

      subject.call(env)
    end

    it "raises an exception if the name doesn't match a requested name" do
      box_path = iso_env.box2_file(:virtualbox)
      tf = Tempfile.new("vagrant").tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5"
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{box_path}"
                }
              ]
            }
          ]
        }
        RAW
        f.close
      end

      env[:box_name] = "foo"
      env[:box_url] = tf.path

      expect(box_collection).to receive(:add).never
      expect(app).to receive(:call).never

      expect { subject.call(env) }.
        to raise_error(Vagrant::Errors::BoxAddNameMismatch)
    end

    it "raises an exception if no matching version" do
      box_path = iso_env.box2_file(:vmware)
      tf = Tempfile.new("vagrant").tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5",
              "providers": [
                {
                  "name": "vmware",
                  "url":  "#{box_path}"
                }
              ]
            },
            { "version": "1.1" }
          ]
        }
        RAW
        f.close
      end

      env[:box_url] = tf.path
      env[:box_version] = "~> 2.0"
      expect(box_collection).to receive(:add).never
      expect(app).to receive(:call).never

      expect { subject.call(env) }.
        to raise_error(Vagrant::Errors::BoxAddNoMatchingVersion)
    end

    it "raises an error if there is no matching provider" do
      tf = Tempfile.new("vagrant").tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5"
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{iso_env.box2_file(:virtualbox)}"
                }
              ]
            }
          ]
        }
        RAW
        f.close
      end

      env[:box_url] = tf.path
      env[:box_provider] = "vmware"
      expect(box_collection).to receive(:add).never
      expect(app).to receive(:call).never

      expect { subject.call(env) }.
        to raise_error(Vagrant::Errors::BoxAddNoMatchingProvider)
    end

    it "raises an error if a box already exists" do
      box_path = iso_env.box2_file(:virtualbox)
      tf = Tempfile.new("vagrant").tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5"
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{box_path}"
                }
              ]
            }
          ]
        }
        RAW
        f.close
      end

      env[:box_url] = tf.path
      expect(box_collection).to receive(:find).
        with("foo/bar", "virtualbox", "0.7").and_return(box)
      expect(box_collection).to receive(:add).never
      expect(app).to receive(:call).never

      expect { subject.call(env) }.
        to raise_error(Vagrant::Errors::BoxAlreadyExists)
    end

    it "force adds a box if specified" do
      box_path = iso_env.box2_file(:virtualbox)
      tf = Tempfile.new("vagrant").tap do |f|
        f.write(<<-RAW)
        {
          "name": "foo/bar",
          "versions": [
            {
              "version": "0.5"
            },
            {
              "version": "0.7",
              "providers": [
                {
                  "name": "virtualbox",
                  "url":  "#{box_path}"
                }
              ]
            }
          ]
        }
        RAW
        f.close
      end

      env[:box_force] = true
      env[:box_url] = tf.path
      box_collection.stub(find: box)
      expect(box_collection).to receive(:add).with { |path, name, version, **opts|
        expect(checksum(path)).to eq(checksum(box_path))
        expect(name).to eq("foo/bar")
        expect(version).to eq("0.7")
        expect(opts[:force]).to be_true
        expect(opts[:metadata_url]).to eq("file://#{tf.path}")
        true
      }.and_return(box)

      expect(app).to receive(:call).with(env)

      subject.call(env)

      expect(env[:box_added]).to equal(box)
    end
  end
end
