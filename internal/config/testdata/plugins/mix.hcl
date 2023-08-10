# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

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
