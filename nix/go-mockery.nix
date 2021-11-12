{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "go-mockery";
  version = "1.1.2";

  src = fetchFromGitHub {
    owner = "vektra";
    repo = "mockery";
    rev = "v${version}";
    sha256 = "16yqhr92n5s0svk31yy3k42764fas694mnqqcny633yi0wqb876a";
  };

  buildFlagsArray = ''
    -ldflags=
    -s -w -X github.com/vektra/mockery/mockery.SemVer=${version}
  '';

  modSha256 = "0wyzfmhk7plazadbi26rzq3w9cmvqz2dd5jsl6kamw53ps5yh536";
  vendorSha256 = "0fai4hs3q822dg36a2zrxb191f71xdpafapn6ymi1w9dx68navcb";

  subPackages = [ "cmd/mockery" ];
}
