{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "go-changelog";
  version = "56335215ce3a8676ba7153be7c444daadcb132c7";

  src = fetchFromGitHub {
    owner = "hashicorp";
    repo = "go-changelog";
    rev = "56335215ce3a8676ba7153be7c444daadcb132c7";
    sha256 = "0z6ysz4x1rim09g9knbc5x5mrasfk6mzsi0h7jn8q4i035y1gg2j";
  };

  vendorSha256 = "1pahh64ayr885kv9rd5i4vh4a6hi1w583wch9n1ncvnckznzsdbg";

  subPackages = [ "cmd/changelog-build" ];
}
