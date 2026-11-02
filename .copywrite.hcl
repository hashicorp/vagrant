schema_version = 1

project {
  license        = "MIT"
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
