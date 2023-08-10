# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

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
