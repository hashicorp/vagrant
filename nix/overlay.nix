final: prev: rec {
  devShells.default = final.callPackage ./vagrant.nix { };
  go-changelog = prev.callPackage ./go-changelog.nix { };
  go-protobuf-json = prev.callPackage ./go-protobuf-json.nix { };
  grpc-tools = prev.callPackage ./grpc-tools.nix { };
}
