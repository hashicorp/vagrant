{ autoPatchelfHook, buildRubyGem, ruby }:

buildRubyGem rec {
  inherit ruby;
  name = "${gemName}-${version}";
  gemName = "grpc-tools";
  version = "1.56.2";
  source.sha256 = "sha256-DBufMPdsZ3Ae0/uT8fyBNajjUeRsP5+CuGyKf+IpAEk=";
  nativeBuildInputs = [ autoPatchelfHook ];
}
