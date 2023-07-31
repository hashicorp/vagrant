# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

project = "hello"

app "tubes" {
    build {
        use "docker" {}
    }

    deploy {
        use "nomad" {}
    }
}
