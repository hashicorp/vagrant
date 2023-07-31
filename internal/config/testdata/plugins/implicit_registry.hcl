# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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
