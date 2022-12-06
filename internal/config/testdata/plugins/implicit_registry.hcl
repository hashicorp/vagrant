project = "hello"

app "tubes" {
    build {
        use "docker" {}

        registry {
            use "aws-ecr" {}
        }
    }

    deploy {
        use "nomad" {}
    }
}
