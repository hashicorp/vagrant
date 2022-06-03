{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "go-mockery";
  version = "2.12.3";

  src = fetchFromGitHub {
    owner = "vektra";
    repo = "mockery";
    rev = "v${version}";
    sha256 = "sha256-3SF8vNYG0PrZhP3zcn9mV85ByQtGDumUcxglf35/eD0";
  };

  buildFlagsArray = ''
    -ldflags=
    -s -w -X github.com/vektra/mockery/v2/pkg/config.SemVer=${version}
  '';

  modSha256 = "sha256-/ha6DCJ+vSOmfFJ+rjN6rfQ3GHZF19OQnmHjYRtSY2g=";
  vendorSha256 = "sha256-/ha6DCJ+vSOmfFJ+rjN6rfQ3GHZF19OQnmHjYRtSY2g=";

  subPackages = ["."];
}
