# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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
