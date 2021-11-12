{ lib
, stdenv
, autoconf
, autogen
, automake
, docker-compose
, doctl
, go
, go-bindata
, go-changelog
, go-mockery
, go-protobuf
, go-protobuf-json
, go-tools
, grpcurl
, kubectl
, libpng
, libtool
, minikube
, mkShell
, nasm
, nodejs-16_x
, pkg-config
, postgresql_12
, protobufPin
, protoc-gen-doc
, zlib
}:

mkShell rec {
  name = "vagrant";

  packages = [
    docker-compose
    go
    go-bindata
    grpcurl
    nodejs-16_x
    postgresql_12
    protoc-gen-doc

    # Custom packages, added to overlay
    protobufPin
    go-protobuf
    go-protobuf-json
    go-tools
    go-mockery
    go-changelog

    # For testing
    doctl
    kubectl

    # Needed for website/
    autoconf
    autogen
    automake
    libpng
    libtool
    nasm
    pkg-config
    zlib
  ] ++ lib.optionals stdenv.isLinux [
    # On Linux we use minikube as the primary k8s testing platform
    minikube
  ];

  # workaround for npm/gulp dep compilation
  # https://github.com/imagemin/optipng-bin/issues/108
  shellHook = ''
    LD=$CC
  '';

  # Extra env vars
  PGHOST = "localhost";
  PGPORT = "5432";
  PGDATABASE = "noop";
  PGUSER = "postgres";
  PGPASSWORD = "postgres";
  DATABASE_URL = "postgresql://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}?sslmode=disable";
}
