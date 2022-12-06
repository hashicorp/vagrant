{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "go-tools";
  version = "35839b7038afa36a6c000733552daa1f5ce1e838";

  src = fetchFromGitHub {
    owner = "golang";
    repo = "tools";
    rev = "35839b7038afa36a6c000733552daa1f5ce1e838";
    sha256 = "1gnqf62s7arqk807gadp4rd2diz1g0v2khwv9wsb50y8k9k4dfqs";
  };

  modSha256 = "1pijbkp7a9n2naicg21ydii6xc0g4jm5bw42lljwaks7211ag8k9";
  vendorSha256 = "0i2fhaj2fd8ii4av1qx87wjkngip9vih8v3i9yr3h28hkq68zkm5";

  subPackages = [ "cmd/stringer" ];

  # This has to be enabled because the stringer tests recompile itself
  # so it needs a valid reference to `go`
  allowGoReference = true;
}
