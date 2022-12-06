project = "hello"

app "tubes" {
    build {
        use "docker" {}
    }

    deploy {
        use "nomad" {}
    }
}
