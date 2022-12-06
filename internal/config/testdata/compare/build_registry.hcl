project = "foo"

app "test" {
    build {
        labels = {
            "foo" = "bar"
        }

        registry {
            use "docker" {}
        }
    }
}
