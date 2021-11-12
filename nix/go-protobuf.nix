{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "go-protobuf";
  version = "1.5.2";

  src = fetchFromGitHub {
    owner = "golang";
    repo = "protobuf";
    rev = "v${version}";
    sha256 = "1mh5fyim42dn821nsd3afnmgscrzzhn3h8rag635d2jnr23r1zhk";
  };

  modSha256 = "0lnk2zpl6y9vnq6h3l42ssghq6iqvmixd86g2drpa4z8xxk116wf";
  vendorSha256 = "1qbndn7k0qqwxqk4ynkjrih7f7h56z1jq2yd62clhj95rca67hh9";

  subPackages = [ "protoc-gen-go" ];
}
