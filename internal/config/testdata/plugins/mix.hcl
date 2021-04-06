project = "hello"

plugin "docker" {
    type {
        deploy = true
    }
}

app "tubes" {
    build {
        use "docker" {}
    }

    deploy {
        use "nomad" {}
    }
}
