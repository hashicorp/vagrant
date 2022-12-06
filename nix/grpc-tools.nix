{ autoPatchelfHook, buildRubyGem, ruby }:

buildRubyGem rec {
  inherit ruby;
  name = "${gemName}-${version}";
  gemName = "grpc-tools";
  version = "1.41.1";
  source.sha256 = "sha256-NlBwd8NRc8niZyOWUheqTgeYs6QP200jDWmEATeBXOE=";
  nativeBuildInputs = [ autoPatchelfHook ];
}
