{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "go-protobuf-json";
  version = "069933b8c8344593ed8905d46d59c6647c886f47";

  src = fetchFromGitHub {
    owner = "mitchellh";
    repo = "protoc-gen-go-json";
    rev = "069933b8c8344593ed8905d46d59c6647c886f47";
    sha256 = "1q5s2pfdxxzvdqghmbw3y2w5nl7wa4x15ngahfarjhahwqsbfsx4";
  };

  modSha256 = "01wrk2qhrh74nkv6davfifdz7jq6fcl3snn4w2g7vr8p0incdlcf";
  vendorSha256 = "1hx31gr3l2f0nc8316c9ipmk1xx435g732msr5b344rcfcfrlaxh";
}
