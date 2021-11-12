final: prev: rec {
  # This is the pinned protoc version we have for this project.
  protobufPin = prev.protobuf3_15;

  ruby = final.ruby_2_7;

  devShell = final.callPackage ./vagrant.nix { };

  go-protobuf = prev.callPackage ./go-protobuf.nix { };

  go-protobuf-json = prev.callPackage ./go-protobuf-json.nix { };

  go-tools = prev.callPackage ./go-tools.nix { };

  go-mockery = prev.callPackage ./go-mockery.nix { };

  go-changelog = prev.callPackage ./go-changelog.nix { };
}
