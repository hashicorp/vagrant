{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "go-mockery";
  version = "2.9.4";

  src = fetchFromGitHub {
    owner = "vektra";
    repo = "mockery";
    rev = "v${version}";
    sha256 = "sha256-y3pbhEqBeOU9DgzowYRH5UcOMOJpWIVgbbA5GlHqH+s=";
  };

  buildFlagsArray = ''
    -ldflags=
    -s -w -X github.com/vektra/mockery/v2/pkg/config.SemVer=${version}
  '';

  modSha256 = "sha256-//V3ia3YP1hPgC1ipScURZ5uXU4A2keoG6dGuwaPBcA=";
  vendorSha256 = "sha256-//V3ia3YP1hPgC1ipScURZ5uXU4A2keoG6dGuwaPBcA=";

  subPackages = ["."];
}
