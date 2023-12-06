schema_version = 1

project {
  license        = "BUSL-1.1"
  copyright_year = 2024

  header_ignore = [
    "internal/pkg/defaults/**",
    "internal/pkg/spinner/**",
    "internal/server/bindata_ui.go",
    "internal/server/gen/**",
    "lib/vagrant/protobufs/**",
    "thirdparty/**",
  ]
}
