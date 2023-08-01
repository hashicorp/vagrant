{
  description = "HashiCorp Vagrant project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-23.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        localOverlay = import ./nix/overlay.nix;
        pkgs = import nixpkgs {
          system = "${system}";
          overlays = [ localOverlay ];
        };
      in { inherit (pkgs) devShells; });
}
