{ lib
, stdenv
, autoconf
, autogen
, automake
, go
, go-bindata
, go-changelog
, go-mockery
, go-protobuf
, go-protobuf-json
, go-tools
, grpc-tools
, grpcurl
, libarchive
, libpng
, libtool
, mkShell
, nasm
, nodejs-16_x
, pkg-config
, protobufPin
, protoc-gen-doc
, ruby
, zlib
}:

mkShell rec {
  name = "vagrant";

  packages = [
    go
    go-bindata
    grpcurl
    nodejs-16_x
    protoc-gen-doc
    ruby

    # Need bsdtar to run ruby tests
    libarchive

    # Custom packages, added to overlay
    protobufPin
    go-protobuf
    go-protobuf-json
    go-tools
    go-mockery
    go-changelog
    grpc-tools

    # Needed for website/
    autoconf
    autogen
    automake
    libpng
    libtool
    nasm
    pkg-config
    zlib
  ];

  # workaround for npm/gulp dep compilation
  # https://github.com/imagemin/optipng-bin/issues/108
  shellHook = ''
    LD=$CC
  '';
}
